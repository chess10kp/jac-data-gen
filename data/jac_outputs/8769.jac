"""Function- uvm_object_value_str

Args:
    v (object): Object to convert to string.
Returns:
    str: Inst ID for `UVMObject`, otherwise uses str()
"""
def uvm_object_value_str(v: object | None) -> str {
    if v is None {
        return "<null>";
    }
    if hasattr(v, 'get_inst_id') {
        return "@" + "{}".format(getattr(v, 'get_inst_id')());
    }
    return str(v);
}