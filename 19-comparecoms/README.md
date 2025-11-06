# Compare commodities

USEEIO commodity codes and CEDA commodity codes do not fully align. This script compares the two code sets and identifies codes that are only in one or the other.

USEEIO commodity metadata is from USEEIOv2.6. CEDA commodity metadata is from CEDA2025. 
These code sets are in the file `coms.csv`.
The output of this script is a list of commodity codes and names that are only in CEDA2025 and only in USEEIOv2.6.

## Results
```
only_in_ceda:
335221 Household cooking appliance manufacturing
335222 Household refrigerator and home freezer manufacturing
335224 Household laundry equipment manufacturing
335228 Other major household appliance manufacturing
562000 Waste management and remediation services

only_in_useeio
33131B Secondary aluminum
335220 Major home appliances
562111 Solid waste collection
562HAZ Hazardous waste collection treatment and disposal
562212 Solid waste landfilling
562213 Solid waste combustors and incinerators
562910 Remediation services
562920 Material separation/recovery facilities
562OTH Other waste collection and treatment services
S00401 Scrap
S00402 Used and secondhand goods
S00300 Noncomparable imports
S00900 Rest of the world adjustment
```
