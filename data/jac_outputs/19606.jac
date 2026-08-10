"""NOTE: get available image name
    For example, `abeja-inc/all-cpu:19.04` locates inside Platform.
    and cannot access it from outside of Platform.
    Therefore let use same images in DockerHub which name starts with `abeja/`.

    """
def convert_to_local_image_name(image: str) -> str {
    if image.startswith('abeja-inc/') {
        return image.replace('abeja-inc/', 'abeja/', 1);
    }
    return image;
}