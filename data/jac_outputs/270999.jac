"""
Get default rough estimate of face bounding box for `get_identity_descriptor()`.

The bounding box in pixels. Defines how much pixels to clip from top, left,
bottom and right in a 256 x 256 image.
"""
def get_default_bbox(kind: str) -> tuple[int, int, int, int] {
    match kind {
        case 'ffhq':
            return (0, 30, 60, 30);
        case 'x2face':
            return (37, (37 + 45) // 2, 45, (37 + 45) // 2);
        case 'latentpose':
            return (42, (42 + 64) // 2, 64, (42 + 64) // 2);
        case _:
            raise ValueError(f"Wrong crop type: {kind}");
    }
}