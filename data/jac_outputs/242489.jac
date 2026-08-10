""" Create an annotation to the image id """
def create_annotation_info(id: int, image_id: int, category_id: int, bbox: list[float]) -> dict[str, int | list[float]] {
    return {
        "id": id,
        "image_id": image_id,
        "category_id": category_id,
        "bbox": bbox,
        "iscrowd": 0
    };
}