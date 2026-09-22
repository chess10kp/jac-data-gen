"""
    This function converts time in a form of integers to a hh:mm:ss format
    Returns an array | Ex: 01:32:34
    """
def convert_time(time: Any) -> object {
    time_list = [(60 * 60), 60, 1];
    output_list = [];
    for i in time_list {
        (amount, remainder) = divmod(time, i);
        if (len(str(amount)) < 2) {
            output_list.append(f'0{str(amount)}');
        } else {
            output_list.append(str(amount));
        }
        time = remainder;
    }
    return ':'.join(output_list);
}