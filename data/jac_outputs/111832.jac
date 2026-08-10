"""Returns the image type from the first few bytes."""
def get_image_mime_type(data: bytes) -> str {
    if data.startswith(b'\x89PNG\r\n\x1a\n') {
        return "image/png";
    } elif data[0:3] == b'\xff\xd8\xff' or data[6:10] in (b'JFIF', b'Exif') {
        return "image/jpeg";
    } elif data.startswith((b'GIF87a', b'GIF89a')) {
        return "image/gif";
    } elif data.startswith(b'RIFF') and data[8:12] == b'WEBP' {
        return "image/webp";
    } else {
        raise ValueError("Unsupported image type given");
    }
}