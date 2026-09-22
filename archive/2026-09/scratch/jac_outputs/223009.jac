"""Get a schema of the config of the dictionary."""
def get_schema(
    dictionary: dict[str, dict | list | int | float | bool | str | None],
    parameters: bool = False,
    delimiter: str = "_"
) -> str {
    global_definition = "";
    def get_key_schema(
        dl: dict[str, dict | list | int | float | bool | str | None] | list[dict | list | int | float | bool | str | None] | int | float | bool | str | None,
        definition: str | None = None
    ) {
        definition = "" if definition is None else definition;
        if isinstance(dl, dict) {
            for key in sorted(dl.keys()) {
                defin = definition + delimiter + key if definition != "" else key;
                get_key_schema(dl[key], defin);
            }
        } elif isinstance(dl, list) {
            for item in sorted(dl) {
                get_key_schema(item, definition);
            }
        } else {
            if parameters {
                final_value = definition + delimiter + str(dl);
            } else {
                final_value = definition + delimiter + "value";
            }
            global_definition += final_value + "\n";
        }
    }
    get_key_schema(dictionary);
    return global_definition;
}