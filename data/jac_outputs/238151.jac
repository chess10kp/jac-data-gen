"""Updates activity by slug."""
def update_activity(p_dict: dict[str, str], slug: str) -> dict[str, str | int | None] {
    updated_param = {
        "name": p_dict["name"] if "name" in p_dict else "Testing Infra",
        "slug": p_dict["slug"] if "slug" in p_dict else slug,
        "uuid": "3cf78d25-411c-4d1f-80c8-a09e5e12cae3",
        "created_at": "2014-04-16",
        "updated_at": "2014-04-17",
        "deleted_at": None,
        "revision": 2
    };
    return updated_param;
}