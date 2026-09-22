"""Return true if the file is an image."""
def is_image_file(filename: str) -> bool {
    return any(
        filename.lower().endswith(extension)
        for extension in ['.png', '.jpg', '.bmp', '.mat']
    );
}