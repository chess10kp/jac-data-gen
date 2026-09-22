"""
    remove 'Class A Common Stock' and 'Common Stock' from listing names
    """
def remove_des(name: str) -> str {
    if name.endswith("Class A Common Stock") {
        name = name[:-21];
    }
    if name.endswith("Common Stock") {
        name = name[:-13];
    }
    name
}