def grade_report(scores: dict[str, int]) -> dict[str, str] {
    out: dict[str, str] = {};
    for (name, s) in scores.items() {
        match s // 10 {
            case 10 | 9: out[name] = "A";
            case 8: out[name] = "B";
            case 7: out[name] = "C";
            case 6: out[name] = "D";
            case _: out[name] = "F";
        }
    }
    return out;
}

with entry {
    print(grade_report({'ana': 91, 'bo': 78, 'cy': 55}));
}
