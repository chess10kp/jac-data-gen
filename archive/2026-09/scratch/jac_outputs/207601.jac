import from _pytest.config { Config }

"""Get pytest options in a version independent way, with allowed defaults."""
def _pytest_get_option(config: Config, name: str, `default: object) -> object {
    try {
        value = config.getoption(name, `default=`default);
    } except Exception {
        try {
            value = config.getvalue(name);
        } except Exception {
            return `default;
        }
    }
    return value;
}