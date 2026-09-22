"""Get kernel response from message pool (Async).

    .. note:: some kernel (iperl) do not discriminate when client asks for
              `user_expressions`. But still they give a printable output.

    Parameters
    ----------
    msgs : list
        List of messages to parse.
    line_number : int
        The message number of the corresponding code.

    Returns
    -------
    str
        The kernel response to the messages.
    """
def parse_iopub_for_reply(msgs: Any, line_number: Any) -> object {
    res = -1;
    for msg in msgs {
        content = msg.get('content', False);
        if not content {
            continue;
        }
        ec = int(content.get('execution_count', 0));
        if not ec {
            continue;
        }
        if (line_number not in (-1, ec)) {
            continue;
        }
        msg_type = msg.get('header', {}).get('msg_type', '');
        if (msg_type not in ('execute_result', 'stream')) {
            continue;
        }
        res = content.get('data', {}).get('text/plain', -1);
        res = res if (res != -1) else content.get('text', -1);
        break;
    }
    return res;
}