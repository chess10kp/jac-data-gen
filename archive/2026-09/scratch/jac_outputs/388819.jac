"""Returns the name of the target start date col for dataframes
    associated with the given forecast identifier."""
def get_target_start_date_col(forecast_id: str) -> str {
    if forecast_id.startswith("nmme") {
        return "target_start";
    }
    if forecast_id.startswith("cfsv2") {
        return "start_date";
    }
    raise ValueError(f"Unrecognized forecast_id {forecast_id}");
}