"""
    :param responses:
    :return:
    """
def success_responses_filter(responses: Any) -> object {
    return [
        each for each in filter(lambda (r: Any) { (r.status_code == 200); }, responses)
    ];
}