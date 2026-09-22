"""Specific method in order to get number of samples of image."""
def get_nsamples_image(filename: str) -> int {
    return int(filename.split('_')[-1].replace('.png', ''));
}