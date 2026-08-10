"""Return the URL to the full size of the file."""
def make_full_size_url(image_name: str) -> str {
    base_url = "http://commons.wikimedia.org/w/index.php?title=Special:FilePath&file=%s";
    return base_url % image_name;
}