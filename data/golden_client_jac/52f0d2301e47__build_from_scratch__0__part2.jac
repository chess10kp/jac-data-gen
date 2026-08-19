def run_length_encode(s: str) -> str {
    if len(s) == 0 {
        return "";
    }
    result = "";
    prev = s[0];
    count = 1;
    for c in s[1:] {
        if c == prev {
            count += 1;
        } else {
            result += f"{prev}{count}";
            prev = c;
            count = 1;
        }
    }
    result += f"{prev}{count}";
    return result;
}

with entry {
    for x in ["aaab", "abc", "wwwww", "aabbaa"] {
        print(run_length_encode(x));
    }
}
