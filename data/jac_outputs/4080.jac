"""Converts strings "true" and "false" from XML files to Python bool"""
def _parse_boolean(xml_boolean: str | None) -> bool | None {
    if xml_boolean is not None {
        assert xml_boolean in ["true", "false"], "The boolean string must be \"true\" or \"false\"";
        return {"true": True, "false": False}[xml_boolean];
    }
}