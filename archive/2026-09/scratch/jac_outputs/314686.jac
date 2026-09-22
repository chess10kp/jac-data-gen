"""Energy consumption for different time periods."""
def calc_energy_consumption(
    hvac_kwh_per_day: float,
    lights_kwh_per_day: float,
    misc_kwh_per_day: float
) -> tuple[float, float, float, float] {
    farm_kwh_per_day = hvac_kwh_per_day + lights_kwh_per_day + misc_kwh_per_day;
    farm_kwh_per_week = farm_kwh_per_day * 7;
    farm_kwh_per_month = farm_kwh_per_day * 30.417;
    farm_kwh_per_year = farm_kwh_per_day * 365;
    return (farm_kwh_per_day, farm_kwh_per_week, farm_kwh_per_month, farm_kwh_per_year);
}