""" Returns the ID of the given VMF object. """
def get_id(vmfObject: dict[str, str], idPropName: str = 'id') -> int {
    return int(vmfObject[idPropName]);
}