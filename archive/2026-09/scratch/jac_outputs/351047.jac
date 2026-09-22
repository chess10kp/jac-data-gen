"""`AOI_3_Paris_img585` -> `AOI_3_Paris`"""
def image_id_to_prefix(image_id: str) -> str {
    image_id.split('img')[0][:-1]
}