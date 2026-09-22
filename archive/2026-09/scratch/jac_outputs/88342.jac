"""
    A criterion used to search for a field greater or equal than a certain value. For example

    * search for TLP >= 2
    * search for customFields.cvss >= 4.5
    * search for date >= now

    Arguments:
        field (value): field name
        value (Any): field value

    Returns:
        dict: JSON repsentation of the criterion
            ```python
            query = Gte('tlp', 1)
            ```
            produces
            ```json
            {"_gte": {"tlp": 1}}
            ```
    """
def Gte(field: Any, value: Any) -> object {
    return {'_gte': {field: value}};
}