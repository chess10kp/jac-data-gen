""" Converts testkit parameter format to driver (python) parameter
    """
def to_param(m: dict[str, object]) -> str | bool | int | float | bytearray | list[object] | dict[str, object] | None {
    data = m["data"] as dict[str, object];
    value = data["value"];
    name = m["name"] as str;
    if name == "CypherNull" {
        return None;
    }
    if name == "CypherString" {
        return str(value);
    }
    if name == "CypherBool" {
        return bool(value);
    }
    if name == "CypherInt" {
        return int(value as int | str | float);
    }
    if name == "CypherFloat" {
        return float(value as int | str | float);
    }
    if name == "CypherString" {
        return str(value);
    }
    if name == "CypherBytes" {
        return bytearray([int(byte, 16) for byte in (value as str).split()]);
    }
    if name == "CypherList" {
        return [to_param(v as dict[str, object]) for v in (value as list[object])];
    }
    if name == "CypherMap" {
        map_value = value as dict[str, object];
        return {k: to_param(map_value[k] as dict[str, object]) for k in map_value};
    }
    raise Exception("Unknown param type " + name);
}