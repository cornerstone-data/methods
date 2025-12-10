"""
Evaluate aluminum industry emissions to air
"""

#%%
# import flowsa
# fbs=flowsa.getFlowBySector('CAP_HAP_national_2020_stewi')

#%% Run the chunk of code to get the stewicombo data aligned to sectors
import flowsa
import stewicombo
import flowsa.data_source_scripts.stewiFBS as s_FBS

# hack to get necessary config inputs for stewi FBS method
config={
    'industry_spec': {'default': 'NAICS_3',
                      'NAICS_4': ['111', '112', '212', '221', '311', '312', '313', '314', '321', '327', '331', '332', '334', '336', '337', '423', '424', '512', '515', '517', '518', '522', '523', '524', '532', '541', '561', '611', '621', '623', '624', '711', '713', '722', '811', '812', '813'],
                      'NAICS_5': ['1111', '1121', '2122', '2123', '3112', '3114', '3115', '3118', '3119', '3121', '3141', '3219', '3221', '3222', '3231', '3241', '3251', '3253', '3255', '3256', '3259', '3261', '3262', '3273', '3279', '3314', '3315', '3323', '3324', '3327', '3331', '3339', '3342', '3346', '3351', '3352', '3359', '3361', '3363', '3371', '3399', '5111', '5112', '5191', '5241', '5416', '5419'],
                      'NAICS_6': ['21311', '31111', '31122', '31151', '31161', '32229', '32311', '32412', '3252', '3254', '32799', '33131', '33141', '33211', '33291', '33299', '33311', '33324', '33331', '33341', '33351', '33361', '33391', '33399', '33411', '33441', '33451', '33522', '33531', '33591', '33599', '33611', '33621', '33641', '33661', '33699', '33712', '33721', '33911', '51731', '52411', '54151', '72251', '23', '92', 'F010']},
    'target_naics_year': 2012,
    'geoscale': 'national', 
    'data_format': 'FBS_outside_flowsa', 
    'activity_schema': 'NAICS_2012_Code', 
    'compartments': ['air'],
    'inventory_dict': {'NEI': 2020, 'TRI': 2020},
    'local_inventory_name': 'NEI_TRI_air_2020'}

inventory_name = config.get('local_inventory_name')

df = None
if inventory_name is not None:
    df = stewicombo.getInventory(inventory_name,
                                 download_if_missing=True)
if df is None:
    # run stewicombo to combine inventories, filter for LCI, remove overlap
    # log.info('generating inventory in stewicombo')
    df = stewicombo.combineFullInventories(
        config['inventory_dict'], filter_for_LCI=True,
        remove_overlap=True, compartments=config.get('compartments'))

facility_mapping = s_FBS.extract_facility_data(config['inventory_dict'])

# merge dataframes to assign facility information based on facility IDs
df = (df.drop(columns=['SRS_CAS', 'SRS_ID', 'FacilityIDs_Combined'])
        .merge(facility_mapping.loc[:, facility_mapping.columns != 'NAICS'],
               how='inner',
               on='FacilityID')
      )

all_NAICS = s_FBS.obtain_NAICS_from_facility_matcher(
    list(config['inventory_dict'].keys()))

df = s_FBS.assign_naics_to_stewicombo(df, all_NAICS, facility_mapping)

# fbs = prepare_stewi_fbs(df, config)

#%% Subset flows and sectors
flows = [
    'Carbon Dioxide',
    'Carbon Monoxide',
    'Sulfur Dioxide',
    'Volatile Organic Compounds',
    'Nitrogen Oxides',
    'PM2.5 Primary (Filt + Cond)',
    ]
aluminum = (df
            .query('NAICS.str.startswith("3313")')
            .query('FlowName in @flows')
            )
aluminum.to_csv('43-aluminum/aluminum_emissions.csv', index=False)
