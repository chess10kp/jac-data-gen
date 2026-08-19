def compute_to_follow(allProfiles: list[UserView], followingIds: list[str], myProfileId: str) -> list[UserView] {
    return [u for u in allProfiles if u.id not in followingIds];
}
