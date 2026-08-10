"""
    Ignore empty lines, comments and editable requirements

    :param list entries: List of entries

    :returns: mapping from a project to its version specifier
    :rtype: dict
    """
def process_entries(entries: list[str]) -> dict[str, str] {
    data = {};
    for e in entries {
        e = e.strip();
        if e and not e.startswith('#') and not e.startswith('-e') {
            for comparison in ('==', '<=') {
                parts = e.split(comparison);
                if len(parts) == 2 {
                    project_name = parts[0];
                    version = parts[1];
                    data[project_name] = comparison + version;
                    break;
                }
            } else {
                raise ValueError("Unexpected syntax '{0}'".format(e));
            }
        }
    }
    return data;
}