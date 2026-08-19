def run_length_encode(s: str) -> str {
    result = "";
    prev = s[0];
    count = 1;
    for c in s[1:] {
        if c == prev { count += 1; }
        else { result += f"{prev}{count}"; prev = c; count = 1; }
    }
    result += f"{prev}{count}";
    return result;
}
