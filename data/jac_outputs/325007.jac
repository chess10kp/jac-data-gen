"""Parse variables passed as args to list of tuples."""
def parse_vars(variables: str) -> list[tuple[str, ...]] {
    list_of_items = variables.split(',') if variables else [];
    parsed_variables: list[tuple[str, ...]] = [];
    for variable in list_of_items {
        if ':' in variable {
            parsed_variables.append(tuple(variable.split(':')));
        } else {
            parsed_variables.append((variable, None));
        }
    }
    parsed_variables
}