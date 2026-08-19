def tab_name(t: str) -> str {
    match t {
        case "feed":
            return "Home";
        case "explore":
            return "Explore";
        case "channels":
            return "Channels";
        case _:
            return "Profile";
    }
}

with entry {
    print(tab_name('feed'));
}
