"""Return whether the processed file is a jpg picture."""
def __is_picture(file: str) -> bool {
    return file.lower().endswith(('jpg', 'jpeg'));
}