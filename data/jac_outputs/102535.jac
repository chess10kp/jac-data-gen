"""Collect all sentences from COCO captions."""
def collect_sentences_coco(data: dict[str, list[dict[str, str]]]) -> list[str] {
    return [ann['caption'] for ann in data['annotations']];
}