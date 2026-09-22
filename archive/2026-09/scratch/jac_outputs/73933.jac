"""Return a console logger.

Output may be sent to the logger using the `debug`, `info`, `warning`,
`error` and `critical` methods.
"""
def get_log(name: str) -> logging.Logger {
    import logging, sys;
    logging.basicConfig(stream=sys.stdout, level=logging.WARNING as int);
    return logging.getLogger(name);
}