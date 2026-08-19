import from byllm.telemetry { register_agent_callback }

glob telemetry_log: list = [];
glob error_log: list = [];

def my_callback(record: dict) -> None {
    telemetry_log.append(record);
    print(f"[{record['caller_name']}] {record['model']} - {record['status']} in {record['latency_ms']:.0f}ms");
    if record["status"] == "error" {
        error_log.append(record);
    }
}

with entry {
    register_agent_callback(my_callback);
}
