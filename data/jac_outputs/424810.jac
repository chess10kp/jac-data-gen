"""Set status for a sample.

    :param parameters: Collected parameters for a  sample

    :returns: string
    """
def set_status(parameters: Any) -> object {
    status = "N/A";
    if (
        ('rounded_read_count' in parameters.keys())
        and ('ordered_amount' in parameters.keys())
    ) {
        if (parameters['rounded_read_count'] >= parameters['ordered_amount']) {
            status = "P";
        }
    } else {
        status = None;
    }
    return status;
}