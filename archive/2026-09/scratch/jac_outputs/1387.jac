"""
The body of the assert check for an accessor.
We allow all versions of add/delete/modify to use the same accessors.
"""
def obj_assert_check(cls: str) -> str {
    if cls in [
        "of_flow_modify",
        "of_flow_modify_strict",
        "of_flow_delete",
        "of_flow_delete_strict",
        "of_flow_add"
    ] {
        return "IS_FLOW_MOD_SUBTYPE(obj->object_id)";
    }
    return "obj->object_id == %s" % cls.upper();
}