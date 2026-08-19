def display_username(profileUsername: str) -> str {
    return profileUsername.split("@")[0]
        if "@" in profileUsername
        else profileUsername;
}

with entry {
    samples = ["alice@example.com", "bob@littlex", "plainname", "", "x@y@z"];
    out = [];
    for s in samples {
        out.append("[" + s + "]->" + display_username(s));
    }
    print(" ".join(out));
}
