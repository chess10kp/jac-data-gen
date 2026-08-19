def get_tab_name(t: str) -> str {
    if t == "feed" {
        return "Home";
    } elif t == "explore" {
        return "Explore";
    } elif t == "channels" {
        return "Channels";
    } else {
        return "Profile";
    }
}
