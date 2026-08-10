"""Forward common arguments for the postgres module."""
def _kwargs(kwargs: dict[str, str | int]) -> dict[str, str | int] {
    return {
        k: v
        for (k, v) in kwargs.items()
        if k in ('user', 'host', 'port', 'maintenance_db', 'password', 'runas')
    };
}