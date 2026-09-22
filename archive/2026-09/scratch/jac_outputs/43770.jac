"""
Returns list of numbers from descriptive range input list.
E.g. ['12-14', '^13', '17'] is converted to [12, 14, 17].
Returns string with error message if unable to parse input.
"""
def convert_range_to_number_list(range_list: list[str]) -> list[int] | str {
    num_list = [];
    exclude_num_list = [];
    try {
        for val in range_list {
            val = val.strip(' ');
            if '^' in val {
                exclude_num_list.append(int(val[1:]));
            } elif '-' in val {
                split_list = val.split("-");
                range_min = int(split_list[0]);
                range_max = int(split_list[1]);
                num_list.extend(range(range_min, range_max + 1));
            } else {
                num_list.append(int(val));
            }
        }
    } except ValueError as exc {
        return "Parse Error: Invalid number in input param 'num_list': %s" % exc;
    }
    return [num for num in num_list if num not in exclude_num_list];
}