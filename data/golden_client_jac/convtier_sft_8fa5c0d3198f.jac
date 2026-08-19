def _pair(chunk: str) -> tuple {
    parts = chunk.split("=");
    if len(parts) != 2 or parts[0] == "" {
        raise ValueError(chunk);
    }
    return (parts[0], parts[1]);
}

def parse_pairs(line: str) -> str {
    good = {};
    bad = 0;
    for chunk in line.split(";") {
        try {
            kv = _pair(chunk);
            good[kv[0]] = kv[1];
        } except ValueError {
            bad += 1;
        }
    }
    return f"{good} bad={bad}";
}

with entry {
    print(parse_pairs('a=1;b=2'));
}
