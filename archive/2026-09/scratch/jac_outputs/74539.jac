"""
    Auto parses the help dialogs provided by developers in the doc strings.
    This is denoted by helpme - text and then a blank line.

    e.g.

    Function doc string
    helpme - more end user friendly message about what this will do

    my arguments...

    """
def parse_help(help_str: str | None) -> str | None {
    result = None;
    if help_str is not None {
        if 'helpme' in help_str {
            z = help_str.split('helpme');
            result = z[-1].split('-')[-1].strip();
        }
    }
    return result;
}