def _norm_tag(word: str) -> str {
    return word.lower().rstrip(".,!?;:");
}

with entry {
    for w in ["#Jac!", "#GRAPH...", "#Hello?;", "#code", "#WOW!!!"] {
        print(_norm_tag(w));
    }
}
