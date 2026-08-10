"""A,C,G,T, depth"""
def cal_percents(count_list: Any) -> object {
    depth = float(count_list[0]);
    if (depth > 0) {
        count_list.append(str((100 * (int(count_list[1]) / depth))));
        count_list.append(str((100 * (int(count_list[2]) / depth))));
        count_list.append(str((100 * (int(count_list[3]) / depth))));
        count_list.append(str((100 * (int(count_list[4]) / depth))));
    } else {
        count_list.append('0.0');
        count_list.append('0.0');
        count_list.append('0.0');
        count_list.append('0.0');
    }
    return count_list;
}