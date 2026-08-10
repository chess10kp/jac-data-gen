"""Prepare a message to notify users that forecasts are ready."""
def prepare_forecast_ready_message(event: dict[str, str | None]) -> str {
    dataset_group = event.get("dataset_group_name");
    message = f"Forecast for {dataset_group} is ready!";
    return message;
}