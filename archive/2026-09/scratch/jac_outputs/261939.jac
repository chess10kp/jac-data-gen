"""

    :param page_number: OCR page number
    :param polygon: The VOTT polygon value for the field
    :return: The populated json attributes
    """
def get_region(page_number: Any, polygon: Any, text: Any) -> object {
    bounding_boxes = [];
    bounding_boxes.append(polygon);
    return {"page": page_number, "text": text, "boundingBoxes": bounding_boxes};
}