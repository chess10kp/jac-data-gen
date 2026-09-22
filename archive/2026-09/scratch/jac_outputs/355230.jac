"""
    Recursively finds element or elements in dict.
    """
def find_element_by_key(`obj: Any, key: Any) -> object {
    path = key.split(".", 1);
    if (len(path) == 1) {
        if isinstance(`obj, `list) {
            return [i.get(path[0]) for i in `obj];
        } elif isinstance(`obj, `dict) {
            return `obj.get(path[0]);
        } else {
            return `obj;
        }
    } elif isinstance(`obj, `list) {
        return [find_element_by_key(i.get(path[0]), path[1]) for i in `obj];
    } elif isinstance(`obj, `dict) {
        return find_element_by_key(`obj.get(path[0]), path[1]);
    } else {
        return `obj;
    }
}