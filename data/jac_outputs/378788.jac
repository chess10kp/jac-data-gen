"""Return True if tran_value ends with rule_value."""
def ENDS_WITH(rule_value: str, tran_value: str) -> bool {
    rule_value = rule_value.lower();
    tran_value = tran_value.lower();
    tran_value = tran_value.strip();
    return tran_value.endswith(rule_value);
}