"""
    LabelBox uses strings for image ids which don't work
    with the coco API (which is used inside of torchvision CocoDetection
    dataset class
    """
def fix_image_ids(data: dict[str, list[dict[str, int | str]]]) -> dict[str, list[dict[str, int | str]]] {
    img_ids: dict[int | str, int] = {};
    for (i, img_data) in enumerate(data['images']) {
        old_id = img_data['id'];
        img_ids[old_id] = i;
        img_data['id'] = i;
    }
    for ann in data['annotations'] {
        ann['image_id'] = img_ids[ann['image_id']];
    }
    return data;
}