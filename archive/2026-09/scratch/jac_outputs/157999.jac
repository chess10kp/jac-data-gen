"""
    Created     20180619   by Magnus Wenzer
    Updated     20180620   by Magnus Wenzer

    Takes an interval in a list and returns a list with the gange of the interval.
    Example: [2, 7] => [2, 3, 4, 5, 6, 7]
    """
def get_list_from_interval(
    input_interval: list[object],
    month_interval: bool = True
) -> list[int] | list[object] | None {
    if not input_interval {
        return None;
    } elif len(set(type(i) for i in input_interval)) != 1 {
        return None;
    }
    if input_interval and len(input_interval) == 2 {
        output_list = [];
        value = input_interval[0] as int;
        while value != (input_interval[-1] as int) {
            output_list.append(value);
            value += 1;
            if input_interval and value == 13 {
                value = 1;
            }
        }
        return [i for i in range(input_interval[0] as int, (input_interval[-1] as int) + 1)];
    }
    output_list = [];
    for item in input_interval {
        output_list.append(
            get_list_from_interval(item as list[object], month_interval=month_interval)
        );
    }
    return output_list;
}