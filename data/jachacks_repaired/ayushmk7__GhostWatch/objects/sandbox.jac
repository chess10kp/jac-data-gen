# objects/sandbox.jac — System 2 sandbox and dependency finding types.

obj SuspiciousDependency {
    has name: str;
    has version: str;
    has manifest_path: str;
    has rule_codes: list;
    has risk_level: str;
}

obj SandboxResult {
    has ecosystem: str;
    has install_ok: bool;
    has outbound_network_observed: bool;
    has file_writes_outside_workspace: bool;
    has child_processes: list;
    has credential_path_access: bool;
    has self_delete_indicators: bool;
    has raw_logs: str;
}

obj BehavioralTrace {
    has summary: str;
    has verdict: str;
    has iocs: list;
}

obj FixValidationResult {
    has passed: bool;
    has install_ok: bool;
    has malicious_signal_removed: bool;
    has notes: str;
}
