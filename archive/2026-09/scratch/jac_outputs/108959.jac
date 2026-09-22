def class_ref(cls: type) -> str {
    return cls.__module__ + "." + cls.__name__;
}