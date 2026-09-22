"""Build docker command to enter bash shell in a container."""
def action_get_into_bash(image_name: str, image_tag: str, user_name: str) -> list[str] {
    image_name_with_tag = image_name + ":" + image_tag;
    return [
        "docker",
        "run",
        "-it",
        image_name_with_tag,
        "/usr/bin/su",
        "-l",
        user_name,
        "-s",
        "/usr/bin/bash"
    ];
}