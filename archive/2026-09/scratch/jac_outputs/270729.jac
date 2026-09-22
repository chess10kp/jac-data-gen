"""Validate limit amount value."""
def validate_limit_amount(amount: Any) -> object {
    errors = [];
    if (not isinstance(amount, float) and not isinstance(amount, int)) {
        errors.append("Amount must be float or integer type.");
        return errors;
    }
    if (amount <= 0) {
        errors.append("Amount must be positive value.");
    }
    return errors;
}