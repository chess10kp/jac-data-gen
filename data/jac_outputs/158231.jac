"""Return an object's name given its objID and a reference objList."""
def getObjName(objID: int, objList: list[list[str | int]]) -> str | None {
    for entry in objList {
        if entry[1] == objID {
            return entry[0] as str;
        }
    }
}