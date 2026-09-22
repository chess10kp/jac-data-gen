""" If we upscale by upscale_factor, then hr_image needs to be
    dividable by upscale_factor to have a valid lr_image. """
def get_valid_crop_size(crop_size: int, upscale_factor: int) -> int {
    return crop_size - crop_size % upscale_factor;
}