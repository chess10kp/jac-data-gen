def typed(v: str) -> any {
    return int(v) if v.lstrip("-").isdigit() else v;
}

def parse_bench(text: str) -> dict {
    marker = "BENCH ";
    hits = [ln.strip() for ln in text.splitlines() if ln.strip().startswith(marker)];
    if not hits {
        return {};
    }
    pairs = [p.split("=", 1) for p in hits[0][len(marker):].split(";") if "=" in p];
    return {kv[0].strip(): typed(kv[1].strip()) for kv in pairs};
}

with entry {
    print(parse_bench('log start\n  BENCH frames=240;avg_ms=-4;label=cpu draw\ndone'));
}
