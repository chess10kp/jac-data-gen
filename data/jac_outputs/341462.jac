"""Checks if simple logging is requested"""
def use_simple_logging(kwargs: Any) -> object {
    return `any(
        [
            (x in kwargs)
            for x in (
                'log_folder',
                'logger_names',
                'log_levels',
                'log_multiproc',
                'log_level'
            )
        ]
    );
}