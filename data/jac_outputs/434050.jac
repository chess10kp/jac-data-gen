"""This is a naming convention for both redis and s3."""
def make_key(app_id: str, app_key: str, task_id: str) -> str {
    return app_id + "/" + app_key + "/" + task_id;
}