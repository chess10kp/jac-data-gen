"""Convert a list of key=value to dict[key]=value"""
def _to_dict(param_list: list[str] | None) -> dict[str, str] | None {
    if param_list {
        return {
            name: value for (name, value) in [param.split('=') for param in param_list]
        };
    }
    return None;
}