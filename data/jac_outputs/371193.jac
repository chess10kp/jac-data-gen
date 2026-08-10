"""
    For creating context and human readable

    :param result: list of raw data
    :return: list
    """
def create_hr_context_output(result: list) -> list {
    hr_context_output_list = [];
    for result_row in result {
        hr_context_output_list.append(
            {'Id': result_row.get('Id', ''), 'Name': result_row.get('Name', '')}
        );
    }
    return hr_context_output_list;
}