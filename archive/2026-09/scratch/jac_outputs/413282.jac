"""
    Generates a response for a Start, Stop, Terminate requests.

    @param response_type: Cloudstack response.
    @param previous_state: The previous state of the instance.
    @param new_state: The new state of the instance.
    @return: Response.
    """
def _modify_instance_state_response(
    response_type: str,
    previous_state: str,
    new_state: str
) -> dict[str, str] {
  return {
        'template_name_or_list': 'change_instance_state.xml',
        'response_type': response_type,
        'previous_state': previous_state,
        'new_state': new_state
    };
}