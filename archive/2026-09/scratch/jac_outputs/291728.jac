"""Sets sampling parameters and returns a dict of sampling parameters."""
def set_sampling_params(
    im_per_scene_per_camera: int = 1,
    intensity_transfer: bool = False,
    target_aug_im_num: int = 5000,
    excluded_camera_models: list[str] | None = None,
    excluded_datasets: list[str] | None = None,
    save_as_16_bits: bool = True,
    remove_saturated_pixels: bool = False,
    saturation_level: float = 0.97,
    output_img_size: list[int] | None = None,
    cropping: bool = True,
    color_temp_balance: bool = True,
    lambda_r: float = 0.7,
    lambda_g: float = 1.2,
    k: int = 15
) -> dict[str, int | bool | float | list[str] | list[int]] {
    if excluded_camera_models is None {
        excluded_camera_models = [];
    }
    if excluded_datasets is None {
        excluded_datasets = [];
    }
    if output_img_size is None {
        output_img_size = [256, 384];
    }
    return {
        'images_per_scene_per_camera': im_per_scene_per_camera,
        'intensity_transfer': intensity_transfer,
        'total_number': target_aug_im_num,
        'excluded_camera_models': excluded_camera_models,
        'excluded_datasets': excluded_datasets,
        'save_as_16_bits': save_as_16_bits,
        'remove_saturated_pixels': remove_saturated_pixels,
        'saturation_level': saturation_level,
        'cropping': cropping,
        'output_image_size': output_img_size,
        'color_temp_balancing': color_temp_balance,
        'lambda_r': lambda_r,
        'lambda_g': lambda_g,
        'k': k
    };
}