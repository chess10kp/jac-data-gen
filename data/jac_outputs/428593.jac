"""
    Sanitizes command options.
    """
def sanitize_command_options(options: Any) -> object {
    multiples = ['badges', 'exclude_badges'];
    for option in multiples {
        if options.get(option) {
            value = options[option];
            if value {
                options[option] = [
                    v
                    for v in value.split(' ')
                    if v
                ];
            }
        }
    }
    return options;
}