"""get a value from a k8s "env" object (array of {"name":x,"value":y}); return None if not found"""
def getenv(
    envarray: Any, key: Any, keyname: Any = "name", valname: Any = "value"
) -> object {
    for e in envarray {
        if (e[keyname] == key) {
            return e[valname];
        }
    }
    return None;
}