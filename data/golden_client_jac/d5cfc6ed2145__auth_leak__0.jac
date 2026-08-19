# Public endpoint -- auto-generates an HTTP API
def:pub add_task(title: str) -> dict { ...; }

# Private -- requires authentication, per-user data isolation
def:priv get_tasks -> list { ...; }

# Protected -- accessible within the module
def:protect helper -> None { ...; }
