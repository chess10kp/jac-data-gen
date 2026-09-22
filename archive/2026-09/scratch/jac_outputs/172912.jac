"""pick an object out of a list of objects using its id"""
def pick_id(id: Any, objects: Any) -> object {
    return list(filter(lambda (o: Any) { (o["id"] == id); }, objects));
}