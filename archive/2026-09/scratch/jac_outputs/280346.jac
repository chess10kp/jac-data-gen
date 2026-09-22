"""Return the Django permcode for the specified HTTP method (e.g. POST => add)."""
def method_to_permcode(method: str) -> str {
    method = method.upper();
    if method == "POST" {
        return "add";
    }
    if method == "GET" {
        return "view";
    }
    if method in ("PUT", "UPDATE") {
        return "change";
    }
    if method == "DELETE" {
        return "delete";
    }
    raise ValueError("Could not derive perm code from method %s" % method);
}