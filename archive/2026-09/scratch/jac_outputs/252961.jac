"""Extracts useful information from video."""
def get_useful_information(info: Any) -> object {
    result = {};
    result['description'] = info['description'];
    result['id'] = info['id'];
    result['thumbnail'] = info['thumbnail'];
    result['title'] = info['title'];
    result['uploader'] = info['uploader'];
    return result;
}