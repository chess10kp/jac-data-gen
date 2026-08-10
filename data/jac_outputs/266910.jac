"""Return json response to user.

If the data is a list, return a response of the json of all objects in that list.
If the data is a json blob, return that as the data.
If the data is None, just return the given status."""
def api_response(data: list | dict[str, object] | None, status: str, code: int = 200) -> tuple[dict[str, object], int] {
    if `type(data) == list {
        return ({"status": status, "data": [obj.json for obj in data]}, code);
    } elif data {
        return ({"status": status, "data": data}, code);
    } else {
        return ({"status": status}, code);
    }
}