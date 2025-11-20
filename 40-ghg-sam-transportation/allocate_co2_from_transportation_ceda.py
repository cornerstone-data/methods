import pandas as pd


from bedrock.ceda_usa.transform.allocation.co2.transportation_aviation_gasoline import (
    allocate_transportation_aviation_gasoline,
)
from bedrock.ceda_usa.transform.allocation.co2.transportation_distillate_fuel_oil import (
    allocate_transportation_distillate_fuel_oil,
)
from bedrock.ceda_usa.transform.allocation.co2.transportation_jet_fuel import (
    allocate_transportation_jet_fuel,
)
from bedrock.ceda_usa.transform.allocation.co2.transportation_lpg import (
    allocate_transportation_lpg,
)
from bedrock.ceda_usa.transform.allocation.co2.transportation_motor_gasoline import (
    allocate_transportation_motor_gasoline,
)
from bedrock.ceda_usa.transform.allocation.co2.transportation_natural_gas import (
    allocate_transportation_natural_gas,
)
from bedrock.ceda_usa.transform.allocation.co2.transportation_residual_fuel import (
    allocate_transportation_residual_fuel,
)


def series_to_emissions_df(series: pd.Series, meta_source: str) -> pd.DataFrame:
    df = series.to_frame(name="allocated_emissions")
    df = df[df["allocated_emissions"] != 0]
    df["emissions_source"] = meta_source
    return df


emissions_aviation_gasoline = series_to_emissions_df(
    allocate_transportation_aviation_gasoline(), "Aviation Gasoline"
)
emissions_distillate_fuel_oil = series_to_emissions_df(
    allocate_transportation_distillate_fuel_oil(), "Distillate Fuel Oil"
)
emissions_jet_fuel = series_to_emissions_df(
    allocate_transportation_jet_fuel(), "Jet Fuel"
)
emissions_lpg = series_to_emissions_df(allocate_transportation_lpg(), "LPG")
emissions_motor_gasoline = series_to_emissions_df(
    allocate_transportation_motor_gasoline(), "Motor Gasoline"
)
emissions_natural_gas = series_to_emissions_df(
    allocate_transportation_natural_gas(), "Natural Gas"
)
emissions_residual_fuel = series_to_emissions_df(
    allocate_transportation_residual_fuel(), "Residual Fuel"
)

pd.concat(
    [
        emissions_aviation_gasoline,
        emissions_distillate_fuel_oil,
        emissions_jet_fuel,
        emissions_lpg,
        emissions_motor_gasoline,
        emissions_natural_gas,
        emissions_residual_fuel,
    ],
    axis=0,
).reset_index().sort_values(by="index", ascending=True).to_csv(
    "40-ghg-sam-transportation/co2_transportation.csv", index=False
)
