"""
    Function to extract and group the corresponding images in a list of all images
    with names like: Step_30_aligned_reference.jpg

    Input:
        image_list: Contains all filenames of the images as string
        subject_id: id of the respective subject.
    Output:
        step_pairs: dictionary with all found image pairs corresponding to one step
                    e.g. {30: [Step_30_aligned_stick.jpg, Step_30_aligned_reference.jpg]}
    """
def sort_imgs(image_list: list[str], subject_id: str, EVAL_TIMES: list[int]) -> dict[int, list[str]] {
    step_pairs = dict();
    for step in EVAL_TIMES {
        step_images = [];
        if step == 120 {
            try {
                step_images.append(
                    [img for img in image_list if img[5:8] == str(step) and img[-13:-4] == "reference"][0]
                );
                step_images.append(
                    [img for img in image_list if img[5:8] == str(step) and img[-9:-4] == "stick"][0]
                );
                step_pairs[step] = step_images;
            } except Exception {
                print("At least one image not found for: {}.".format(subject_id));
            }
        } else {
            try {
                step_images.append(
                    [img for img in image_list if img[5:7] == str(step) and img[-13:-4] == "reference"][0]
                );
                step_images.append(
                    [img for img in image_list if img[5:7] == str(step) and img[-9:-4] == "stick"][0]
                );
                step_pairs[step] = step_images;
            } except Exception {
                print("At least one image not found for: {}.".format(subject_id));
            }
        }
    }
    return step_pairs;
}