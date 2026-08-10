"""Try converting the value to a number."""
def try_number(value: int | str | float) -> int | float | str {
    try {
        return int(value);
    } except ValueError {
        try {
            return float(value);
        } except ValueError {
            return value;
        }
    }
}