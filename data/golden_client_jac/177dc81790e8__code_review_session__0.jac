node User { has name: str; }

def helper -> int { return 42; }
def:pub api_function -> None { }
def:priv internal_helper -> None { }

walker:pub GetUsers {
    can get with `root entry {
        report [-->][?:User];
    }
}

walker:priv InternalProcess { }
