"""Tries to convert value to the relevant type by re-typing."""
def hard_retype(value: str) -> int | float | bool | str {
    try {
        return int(value);
    } except ValueError {
        try {
            return float(value);
        } except ValueError {
            if value.lower() in ('true', 'false') {
                return value.lower() == 'true';
            }
            return value;
        }
    }
}