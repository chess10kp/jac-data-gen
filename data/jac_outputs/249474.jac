"""Writes envvar file using env var dict."""
def create_envvar_file(env_file_path: str, envvars: dict[str, str]) -> bool {
    with open(env_file_path, "w+") as f {
        for (key, value) in envvars.items() {
            f.write(f"{key}={value}\n");
        }
    }
    return True;
}