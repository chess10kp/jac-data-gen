def display_username(profileUsername: str) -> str {
    if "@" in profileUsername {
        return profileUsername.split("@")[0];
    }
    return profileUsername;
}
