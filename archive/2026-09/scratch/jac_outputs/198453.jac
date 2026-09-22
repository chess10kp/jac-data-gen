"""Bounding box for text node."""
def bounding_box_text(svg: str, `node: dict[str, str | None], font_size: float) -> str | None {
    return `node.get('text_bounding_box');
}