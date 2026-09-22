""" extended get of an attribute of the cluster API with, recoursion (deep get), defaulting & validation """
def getx(data: Any, keys: Any, `default: Any = None, validator: Any = None) -> object {
    for key in keys.split('.') {
        try {
            data = data[key];
        } except KeyError {
            if (`default != None) {
                return `default;
            } else {
                raise KeyError(
                    ("invalid cluster API definition. Key '%s' does not exist" % keys)
                );
            }
        }
    }
    if (validator != None) {
        validator(data);
    }
    return data;
}