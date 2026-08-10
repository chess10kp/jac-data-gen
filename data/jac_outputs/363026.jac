"""Format vertex data."""
def format_vertex(body: dict[str, dict[str, str]]) -> dict[str, dict[str, str]] | dict[str, str] {
    vertex = body["vertex"];
    if "_oldRev" in vertex {
        vertex["_old_rev"] = vertex.pop("_oldRev");
    }
    if "new" in body or "old" in body {
        result = {"vertex": vertex};
        if "new" in body {
            result["new"] = body["new"];
        }
        if "old" in body {
            result["old"] = body["old"];
        }
        return result;
    }
    return vertex;
}