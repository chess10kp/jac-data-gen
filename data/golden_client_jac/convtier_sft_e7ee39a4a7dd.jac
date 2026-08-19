def shade_rgb(spec: dict) -> list {
    pct = spec["pct"];
    return [min(c * pct // 100, 255) for c in spec["rgb"]];
}

with entry {
    print(shade_rgb({'rgb': [100, 200, 40], 'pct': 150}));
}
