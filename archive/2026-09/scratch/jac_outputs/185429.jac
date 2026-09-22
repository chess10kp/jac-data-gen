""" Join an image name and tag. """
def join_image_tag(image: str, tag: str) -> str {
    if not tag {
        return image;
    }
    return ':'.join((image, tag));
}