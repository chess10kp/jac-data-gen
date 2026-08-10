"""Builds a json string containing response from vision api."""
def build_json(image_content: str) -> dict[str, list[dict[str, dict[str, str] | list[dict[str, str | int]]]]] {
    return {
        'requests': [
            {
                'image': {'content': image_content},
                'features': [{'type': 'FACE_DETECTION', 'maxResults': 1}]
            }
        ]
    };
}