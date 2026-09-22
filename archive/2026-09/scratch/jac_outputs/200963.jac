"""

    :param params_num:
    :type params_num:
    :return:
    :rtype:"""
def params_to_string(params_num: Any) -> str {
    if ((params_num // (10 ** 6)) > 0) {
        return (str(round((params_num / (10 ** 6)), 2)) + " M");
    } elif (params_num // (10 ** 3)) {
        return (str(round((params_num / (10 ** 3)), 2)) + " k");
    } else {
        return str(params_num);
    }
}