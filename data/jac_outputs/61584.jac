"""
Get extra options which are appropriate for
    pipeline_printout
    pipeline_printout_graph
    pipeline_run
"""
def get_extra_options_appropriate_for_command(
    appropriate_option_names: list[str], extra_options: dict[str, str]
) -> dict[str, str] {
    appropriate_options = dict();
    for option_name in appropriate_option_names {
        if option_name in extra_options {
            appropriate_options[option_name] = extra_options[option_name];
        }
    }
    return appropriate_options;
}