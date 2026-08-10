"""Create an image details message for the GUI client."""
def create_deets_message(time: str, size: tuple[int, int], image: str) -> str {
    time_type = "processed" if "inverted" in image else "uploaded";
    (width, height) = size;
    return "Time {}: {}\nImage size: {} x {}".format(time_type, time, width, height);
}