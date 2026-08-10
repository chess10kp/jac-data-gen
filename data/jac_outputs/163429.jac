"""Append an entry if it doesn't have it. Returns true if an
entry was appened, false otherwise."""
def append_entry(data: list[tuple[str, str]], name: str, path: str) -> bool {
    found = False;
    for entry in data {
        if path == entry[1] {
            found = True;
            break;
        }
    }
    if not found {
        data.append((name, path));
        return True;
    }
    return False;
}