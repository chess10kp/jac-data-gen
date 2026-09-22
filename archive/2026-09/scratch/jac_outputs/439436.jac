"""Replaces all * wildcards with n copies that each have appended one element from the provided suffixList and replaces %id wildcards with myId
    ex: objectList = [a, b, c_3, d_*, e_%id], suffixList=['0', '1', '2'], myId=5 => objectList = [a, b, c_3, e_5, d_0, d_1, d_2]"""
def processObjectListWildcards(objectList: list[str], suffixList: list[str], myId: str) -> list[str] {
    for item in objectList[:] {
        if '*' in item {
            for suffix in suffixList {
                objectList.append(item.replace("*", suffix));
            }
            objectList.remove(item);
        }
        if '%id' in item {
            objectList.append(item.replace("%id", myId));
            objectList.remove(item);
        }
    }
    return objectList;
}