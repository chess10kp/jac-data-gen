"""_norm_tag: declaration separated from its impl body."""

def _norm_tag(word: str) -> str;

impl _norm_tag {
    return word.lower().rstrip(".,!?;:");
}

with entry {
    for w in ["#Jac!", "#GRAPH...", "#Hello?;", "#code", "#WOW!!!"] {
        print(_norm_tag(w));
    }
}
