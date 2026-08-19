"""Map a tab key to its header label as a single nested conditional expression."""

def get_tab_name(t: str) -> str {
    return (
        "Home"
            if t == "feed"
            else (
                "Explore"
                    if t == "explore"
                    else ("Channels" if t == "channels" else "Profile")
            )
    );
}

with entry {
    keys = ["feed", "explore", "channels", "profile", "unknown"];
    out = [];
    for k in keys {
        out.append(k + "=" + get_tab_name(k));
    }
    print(" ".join(out));
}
