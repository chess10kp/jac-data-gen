"""
    Returns true if 'base' is an ancestor of 'name'.
    Particularly useful for checking if a given Vulkan type descends from VkDevice or VkInstance.
    """
def isAncestor(types: dict[str, dict[str, str]], name: str, base: str) -> bool {
    if name == base {
        return True;
    }
    `type = types.get(name);
    if `type is None {
        return False;
    }
    parent = `type.get('parent');
    if not parent {
        return False;
    }
    return isAncestor(types, parent, base);
}