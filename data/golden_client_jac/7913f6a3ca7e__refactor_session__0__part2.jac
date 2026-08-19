"""display_username: conditional expression expanded into an explicit guard."""

def display_username(profileUsername: str) -> str {
    if "@" in profileUsername {
        return profileUsername.split("@")[0];
    }
    return profileUsername;
}

with entry {
    samples = ["alice@example.com", "bob@littlex", "plainname", "", "x@y@z"];
    out = [];
    for s in samples {
        out.append("[" + s + "]->" + display_username(s));
    }
    print(" ".join(out));
}
