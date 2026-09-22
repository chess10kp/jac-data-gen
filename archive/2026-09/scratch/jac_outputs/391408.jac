"""Transforms series of water usage in 15 minutes intervals into 1 hour intervals.

    :param usage_list: list of numbers
    :return: list of numbers(usage hourly)
    """
def usage15minTo1hTransform(usage_list: Any) -> object {
    usage = [];
    for i in range(0, (len(usage_list) - 1), 4) {
        h = (
            float(usage_list[i])
            + float(usage_list[(i + 1)])
            + float(usage_list[(i + 2)])
            + float(usage_list[(i + 3)])
        );
        usage.append(round(h, 2));
    }
    return usage;
}