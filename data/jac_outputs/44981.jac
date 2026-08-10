"""Verify Allow header methods."""
def verify_allow(value: str | None, expected: list[str]) -> bool {
    if value is None {
        return False;
    }
    header = value;
    if header[-1] == "," {
        header = header[:-1];
    }
    methods = [m.strip() for m in header.split(",")];
    if len(expected) != len(methods) {
        return False;
    }
    for exp in expected {
        if exp not in methods {
            return False;
        }
    }
    return True;
}