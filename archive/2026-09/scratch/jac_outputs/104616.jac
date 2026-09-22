""" give a 3x3 matrix ,find the sum of all its elements
    """
def sum_sub_image(sub_image: Any) -> object {
    total = 0;
    for row in range(3) {
        for col in range(3) {
            total += sub_image[row][col];
        }
    }
    return (total // 9);
}