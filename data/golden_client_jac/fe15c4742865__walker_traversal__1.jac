def:pub get_status() -> dict {
    return {"status": "ok"};
}

def:priv get_user_data() -> dict {
    # Each user sees their own data automatically
    return {"user": "data"};
}
