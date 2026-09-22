"""Return user-data entries for remote host user creation."""
def get_users(username: str, public_key: str) -> list[dict[str, str | list[str]]] {
    return [
        {
            "name": username,
            "groups": ["sudo"],
            "shell": "/bin/bash",
            "sudo": ["ALL=(ALL) NOPASSWD:ALL"],
            "ssh-authorized-keys": [public_key]
        }
    ];
}