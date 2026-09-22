"""Return legacy qos policy information if present in extra specs."""
def get_legacy_qos_policy(extra_specs: dict[str, object]) -> dict[str, object] | None {
    external_policy_name = extra_specs.get('netapp:qos_policy_group');
    if external_policy_name is None {
        return None;
    }
    return dict(policy_name=external_policy_name);
}