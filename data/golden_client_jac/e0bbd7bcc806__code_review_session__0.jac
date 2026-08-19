import from byllm.lib { Image }

obj ImageDescription {
    has caption: str;
    has objects: list[str];
}

"""Describe what you see in this image."""
def describe_image(img: Image) -> ImageDescription by llm();
