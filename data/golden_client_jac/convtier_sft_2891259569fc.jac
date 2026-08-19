def safe_ratio(spec: str) -> str {
    try {
        parts = spec.split("/");
        a = int(parts[0]);
        b = int(parts[1]);
        return str(a / b);
    } except ZeroDivisionError {
        return "undefined";
    } except (ValueError, IndexError) {
        return "bad input";
    }
}

with entry {
    print(safe_ratio('8/2'));
}
