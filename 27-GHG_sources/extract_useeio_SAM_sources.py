"""
Extracts and sorts GHG FBS by GHGI Table and Attribution Source
Uses data year 2023
https://zenodo.org/records/17208591
"""

import flowsa
from flowsa.common import load_yaml_dict
import pandas as pd
import lciafmt
fbs = flowsa.getFlowBySector('GHG_national_2023_m2_v2.1.0_c25c206')

# Apply AR-6 100 yr, but make sure not to drop the kg CO2e flows in the FBS
df = (pd.concat([
        lciafmt.apply_lcia_method(fbs, 'IPCC').query('Indicator == "AR6-100"'),
        fbs.query('Unit == "kg CO2e"')])
    .assign(Impact = lambda x: x['Impact'].fillna(x['FlowAmount']))
    )

# Extract the Table descriptions from the FBA config
config = load_yaml_dict('EPA_GHGI', flowbytype='FBA')
new_dicts = [value for value in config['Tables'].values()]
new_dicts.extend([value for value in config['Annex'].values()])
table_dict = {}
for d in new_dicts:
    table_dict |= d
table_dict = {f"EPA_GHGI_T_{key.replace('-', '_')}": value['desc'] for key, value in table_dict.items()}
del d, new_dicts

# Totals by Source and Flow, sorted
flows = (df.groupby(['Flowable', 'MetaSources', 'AttributionSources'])
          .agg({'Impact':'sum'})
          .reset_index()
          .sort_values(by='Impact', ascending=False))

# Totals by Source, sorted
totals = (df.groupby(['MetaSources', 'AttributionSources', 'SourceName'], dropna=False)
          .agg({'Impact':'sum'})
          .reset_index()
          .sort_values(by='Impact', ascending=False)
          .assign(Table = lambda x: x['MetaSources'].str.rsplit('.', n=1).str.get(0))
          .assign(a_set = lambda x: x['MetaSources'].str.rsplit('.', n=1).str.get(1)).fillna('')
          )


totals['Description'] = totals['Table'].map(table_dict)
totals = (totals.groupby(['Description', 'AttributionSources'], dropna=False)
          .agg(Impact = ('Impact','sum'),
               # join activity_sets with comma
               a_sets=('a_set', lambda x: ", ".join(sorted(set(x.dropna()))))
               )
          .reset_index()
          .assign(Rank = lambda x: x['Impact'].rank(ascending=False).astype('int'))
          .sort_values(by='Rank')
          .assign(CumulativeImpact = lambda x: 
                      (x['Impact'].cumsum() / x['Impact'].sum() * 100).round(1))
          )

print(totals[['Rank', 'Description', 'AttributionSources', 'a_sets', 'CumulativeImpact']])
(totals[['Rank', 'Description', 'AttributionSources', 'a_sets', 'CumulativeImpact']]
 .to_csv('27-GHG_sources/useeio_SAM_sources.csv', index=False))
