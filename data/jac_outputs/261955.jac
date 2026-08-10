"""docstring for bbox2center"""
def bbox2center(bbox: Any) -> object {
    return [int(((bbox[0] + bbox[2]) / 2)), int(((bbox[1] + bbox[3]) / 2))];
}