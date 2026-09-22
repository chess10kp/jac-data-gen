"""Convert Notion User objects to a "simple" dictionary suitable for Pandas.

This is suitable for objects that have `"object": "user"`"""
def _user_to_simple_dict(user: dict[str, str | dict[str, str]]) -> dict[str, str] {
    record: dict[str, str] = {
        "notion_id": user["id"] as str,
        "type": user["type"] as str,
        "name": user["name"] as str,
        "avatar_url": user["avatar_url"] as str
    };
    if user["type"] == "person" {
        record["email"] = (user["person"] as dict[str, str])["email"];
    }
    return record;
}