"""Get Attributes of a Class."""
def get_user_attributes(cls: type, exclude_methods: bool = True) -> list[str] {
    base_attrs = dir(`type('dummy', (object, ), {}));
    this_cls_attrs = dir(cls);
    res: list[str] = [];
    for attr in this_cls_attrs {
        if base_attrs.count(attr) or callable(getattr(cls, attr)) and exclude_methods {
            continue;
        }
        res += [attr];
    }
    return res;
}