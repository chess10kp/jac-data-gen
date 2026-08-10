"""
    :param img_ratio: Float
    :param monitor_ratio: Float
    :param file: Str
    :return: Bool
    """
def same_ratio(img_ratio: Any, monitor_ratio: Any, file: Any) -> object {
    percent = img_ratio / monitor_ratio;
    diff = int((abs((percent - 1)) * 100));
    if (percent > 1) {
        print(
            (
                "Image is "
                + str(diff)
                + "% too wide for screen. Sides must be cropped off, or top/bottom filled."
            )
        );
        same = False;
    } elif (percent < 1) {
        print(
            (
                "Image is "
                + str(diff)
                + "% too narrow for screen. Top/bottom must be cropped off, or sides filled."
            )
        );
        same = False;
    } else {
        print("Image is the same aspect ratio as the screen.");
        n = input("Press enter to exit.");
        same = True;
    }
    return same;
}