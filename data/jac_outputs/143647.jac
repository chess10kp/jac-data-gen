"""Make the list of verbs into present participles."""
def make_present_participles(verbs: list[str]) -> list[str] {
    res = [];
    for verb in verbs {
        parts = verb.split();
        if parts[0].endswith("e") {
            parts[0] = parts[0][:-1] + "ing";
        } else {
            parts[0] = parts[0] + "ing";
        }
        res.append(" ".join(parts));
    }
    return res;
}