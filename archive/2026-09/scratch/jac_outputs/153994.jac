"""Returns Included Role"""
def get_include_role(validation: dict[str, list[dict[str, dict[str, str]]] | list[str | dict[str, str | dict[str, str]]]]) -> str | list[str] | dict[str, str | dict[str, str]] {
    try {
        if 'tasks' in validation {
            return validation['tasks'][0]['include_role']['name'];
        }
        return validation['roles'][0];
    } except KeyError {
        return list();
    }
}