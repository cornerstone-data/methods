import pandas as pd
import math

coms = pd.read_csv("1-comparecoms/coms.csv")

ceda_coms = dict(zip(coms["ceda_code"], coms["ceda_name"]))
useeio_coms = dict(zip(coms["useeio_code"], coms["useeio_name"]))

keys_to_remove = []
for key, value in ceda_coms.items():
    if isinstance(value, float) and math.isnan(value):
        keys_to_remove.append(key)

for key in keys_to_remove:
    del ceda_coms[key]


#ceda_coms = set(coms["CEDA2025"].dropna())
#useeio_coms = set(coms["USEEIOv2.6"].dropna)

only_in_ceda = (ceda_coms.keys() - useeio_coms.keys())
print("only_in_ceda:")
{print(key,value) for key,value in ceda_coms.items() if key in only_in_ceda}

only_in_useeio = (useeio_coms.keys() - ceda_coms.keys())
print("only_in_useeio")
{print(key,value) for key,value in useeio_coms.items() if key in only_in_useeio}
