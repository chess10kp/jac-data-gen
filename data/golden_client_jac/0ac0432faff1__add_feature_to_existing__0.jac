def my_callback(record: dict) -> None {
    telemetry_log.append(record);
    if record["status"] == "error" {
        error_log.append(record);
    }
}
