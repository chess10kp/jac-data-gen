"""Creates HTML image tag. Optionaly, twitter size param can be passed."""
def create_image(src: Any, size: Any = None) -> object {
    if (size is None) {
        return "<image src=\"{}\" />".format(src);
    } else {
        return "<image src=\"{}:{}\" />".format(src, size);
    }
}