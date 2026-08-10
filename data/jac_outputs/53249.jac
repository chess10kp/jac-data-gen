"""
    maps the xml value of an Object's "MultipleInstances" to a boolean, that represents if the object can be instanced.
    this is useful to optimize memory usage of the generated code
    :param obj_multiple_instances:
    :return:
    """
def obj_is_multiple(obj_multiple_instances: str) -> bool {
    obj_multiple_instances.upper() == "MULTIPLE"
}