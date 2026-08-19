# Public by default
def helper -> int { return 42; }

# Explicitly public
def:pub api_function -> None { }

# Private to module
def:priv internal_helper -> None { }

# Public walker (becomes API endpoint with jac start)
walker:pub GetUsers { }

# Private walker
walker:priv InternalProcess { }
