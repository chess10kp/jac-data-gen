import litellm;
import from litellm.integrations.custom_logger { CustomLogger }
import from byllm.telemetry { register_agent_callback }

glob llm_call_records: list = [],
     agent_records: list = [];

obj UserTelemetryLogger(CustomLogger) {
    def log_success_event(
        kwargs: dict,
        response_obj: object,
        start_time: object,
        end_time: object
    ) -> None {
        slp = kwargs.get("standard_logging_object", {}) or {};
        metadata = kwargs.get("litellm_params", {}).get("metadata", {}) or {};
        llm_call_records.append({
            "invocation_id": metadata.get("jac_invocation_id", ""),
            "model": slp.get("model") or kwargs.get("model"),
            "total_tokens": slp.get("total_tokens") or 0,
            "cost": slp.get("response_cost") or 0.0
        });
    }
}

def capture_agent(record: dict) -> None {
    agent_records.append(record);
}
