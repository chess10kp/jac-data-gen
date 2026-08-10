"""
    :param eventcode: list of event codes from operant conditioning file
    :return: number of successful go and no go trials in the go/no go tasks
    """
def num_successful_go_nogo_trials(eventcode: Any) -> object {
    return (
        eventcode.count('SuccessfulGoTrial'),
        eventcode.count('SuccessfulNoGoTrial')
    );
}