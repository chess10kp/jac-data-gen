"""
    Filter down the complete dict from Vote Smart to just the fields we use locally
    :param one_state:
    :return:
    """
def vote_smart_state_filter(one_state: Any) -> object {
    one_state_filtered = {'stateId': one_state['stateId'], 'name': one_state['name']};
    return one_state_filtered;
}