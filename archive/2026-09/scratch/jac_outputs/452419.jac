"""Randomly select one transformation from {color} transformations,
        and then randomly select two transformations from {shape} transformations."""
def policy_v2_1(probability: Any = 0.7, magnitude: Any = 5) -> object {
    policy = {
        0: [
            [('Mixup', probability, magnitude)],
            [('Gaussian_noise', probability, magnitude)],
            [('Saturation', probability, magnitude)],
            [('Contrast', probability, magnitude)],
            [('Brightness', probability, magnitude)],
            [('Sharpness', probability, magnitude)],
            [('Color_casting', probability, magnitude)],
            [('Equalize_YUV', probability, magnitude)],
            [('Posterize', probability, magnitude)],
            [('AutoContrast', probability, magnitude)],
            [('Solarize', probability, magnitude)],
            [('Equalize', probability, magnitude)],
            [('Vignetting', probability, magnitude)]
        ],
        1: [
            [('Rotate', probability, magnitude)],
            [('Flip', probability, magnitude)],
            [('Cutout', probability, magnitude)],
            [('Shear_x', probability, magnitude)],
            [('Shear_y', probability, magnitude)],
            [('Scale', probability, magnitude)],
            [('Scale_xy_diff', probability, magnitude)],
            [('Lens_distortion', probability, magnitude)]
        ],
        2: [
            [('Rotate', probability, magnitude)],
            [('Flip', probability, magnitude)],
            [('Cutout', probability, magnitude)],
            [('Shear_x', probability, magnitude)],
            [('Shear_y', probability, magnitude)],
            [('Scale', probability, magnitude)],
            [('Scale_xy_diff', probability, magnitude)],
            [('Lens_distortion', probability, magnitude)]
        ]
    };
    return policy;
}