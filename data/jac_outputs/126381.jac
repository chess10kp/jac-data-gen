"""
    ----------
    Author: Damon Gwinn (gwinndr)
    ----------
    - Computes embedding information for a letterbox input format
    - Information is the size of the embedded image and where the embedded image is in the letterbox
    ----------
    """
def get_letterbox_image_embedding(
    img_h: Any, img_w: Any, target_letterbox_dim: Any
) -> object {
    ratio = img_w / img_h;
    if (img_w >= img_h) {
        embed_w = target_letterbox_dim;
        embed_h = round((embed_w / ratio));
    } else {
        embed_h = target_letterbox_dim;
        embed_w = round((embed_h * ratio));
    }
    start_x = (target_letterbox_dim - embed_w) // 2;
    start_y = (target_letterbox_dim - embed_h) // 2;
    return (embed_h, embed_w, start_y, start_x);
}