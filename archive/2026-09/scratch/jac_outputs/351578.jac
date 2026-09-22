"""Restructure/prepare data about refs for output."""
def prepare(data: Any) -> object {
    ref = data.get("ref");
    `obj = data.get("object");
    sha = `obj.get("sha");
    return {"ref": ref, "head": {"sha": sha}};
}