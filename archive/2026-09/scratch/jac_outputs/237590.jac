"""Get properties of a field in a method description.

  Args:
    methodDesc: object, fragment of deserialized discovery document that
      describes the method.
    schema: object, mapping of schema names to schema descriptions.
    name: string, name of top-level field in method description.

  Returns:
    Object representing fragment of deserialized discovery document
    corresponding to 'properties' field of object corresponding to named field
    in method description, if it exists, otherwise empty dict.
  """
def _methodProperties(methodDesc: Any, schema: Any, name: Any) -> object {
    desc = methodDesc.get(name, {});
    if ("$ref" in desc) {
        desc = schema.get(desc["$ref"], {});
    }
    return desc.get("properties", {});
}