"""
    obtains the kahan queue id from the output of the qsub command
    :param output list with all the output lines from kahan server
    """
def get_kahan_queue_id(output: list) -> object {
    return output[0] if ((len(output) > 0) and output[0].isdigit()) else None;
}