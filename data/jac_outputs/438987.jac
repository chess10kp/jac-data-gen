"""Get image type."""
def get_image_type(fileName: str) -> str | None {
    if fileName.endswith(".jpg") {
        return "image/jpeg";
    } elif fileName.endswith(".png") {
        return "image/png";
    }
}