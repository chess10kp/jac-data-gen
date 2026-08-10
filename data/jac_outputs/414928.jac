"""value is a float representing a surface using square kilometers as unit
    this tag simply format mille with space and leave only two digits in decimals"""
def sq_km(value: Any) -> object {
    if not isinstance(value, str) {
        value = str(value);
    }
    try {
        (integer, decimal) = value.split(".");
    } except ValueError {
        integer = value;
        decimal = "00";
    }
    if (not integer.isdigit() or not decimal.isdigit()) {
        return value;
    }
    chunks = [];
    while integer {
        if (len(integer) >= 3) {
            chunks.insert(0, integer[-3:]);
            integer = integer[:-3];
        } else {
            chunks.insert(0, integer);
            integer = None;
        }
    }
    integer = " ".join(chunks);
    return f"{integer},{decimal[:2]}";
}