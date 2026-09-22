"""
This function is for creating position list.
The list contains those features occurs less than given number.
"""
def noise_pos(feature: list[tuple[int, list[int]]], thres: int) -> list[int] {
    n_pos = [];
    for i in range(len(feature[0][1])) {
        max_num = 0;
        for j in range(len(feature)) {
            max_num = max(feature[j][1][i], max_num);
        }
        if max_num < thres {
            n_pos.append(i);
        }
    }
    return n_pos;
}