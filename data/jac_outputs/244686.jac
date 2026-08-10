"""Split a string into a list of numeric and non-numeric substrings."""
def to_bits(cs: str) -> list[str] {
    if not cs {
        return [];
    }
    out = [];
    tmp = "";
    is_number = True;
    first = True;
    for c in cs {
        if c in '0123456789' {
            if is_number {
                tmp += c;
            } else {
                if not first {
                    out.append(tmp);
                }
                tmp = c;
                is_number = True;
            }
        } elif is_number {
            if not first {
                out.append(tmp);
            }
            tmp = c;
            is_number = False;
        } else {
            tmp += c;
        }
        first = False;
    }
    if not first {
        out.append(tmp);
    }
    return out;
}