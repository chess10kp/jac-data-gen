"""Returns the correct dataset name for datasets beginning with numbers."""
def name_converter(name: str) -> str {
    {"jid_editorial_images_2018": "2018 JID Editorial Images"}.get(name, name)
}