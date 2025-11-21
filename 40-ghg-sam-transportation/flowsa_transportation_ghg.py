"""
Method to run the 2023 GHG FBS for transportation emissions
"""

# todo: modify to use bedrock flowsa once we establish remote data storage

from flowsa.flowbysector import FlowBySector
from flowsa import getFlowBySector

import pandas as pd

# method name
m = "GHG_national_2023_m1"

# generate the GHG FBS - this line of code will always generate a new FBS, it will not load a local copy
# recommended to generate the FBAs locally, as set up to pull from EPA Data Commons
fbs = FlowBySector.generateFlowBySector(
       m,
       retain_activity_columns = True,
       download_sources_ok=False  # optionally download FBA data used to generate FBS
)
# optionally, comment in to load local version only if local copy has activty column
# fbs = getFlowBySector(m)

# subset data to transportation table
fbs_sub = (fbs
           .query("MetaSources.str.startswith('EPA_GHGI_T_3_13')")
           .reset_index(drop=True)
           )

# drop unneccessary columns for review
fbs_sub = fbs_sub[['Flowable', 'Class', 'SectorProducedBy', 'Context',
       'FlowAmount', 'Unit', 'FlowType', 'Year', 'MetaSources',
       'ActivityProducedBy', 'AttributionSources']]

fbs_sub.to_csv(
    "40-ghg-sam-transportation/flowsa_GHG_national_2023_m1_transportation.csv", index=False
)

