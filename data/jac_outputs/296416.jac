"""'Empty' TFRs are NOTAM-TFRs which are NOTAM-TFRs that have been
    sent previously, and are active, but which every other cycle is sent
    with no text-- Just with it's number, an empty text field, and an
    indication that it is still active.

    Args:
        frame (dict): Frame with product id of 8.

    Returns:
        Empty string if this cannot be an empty TFR. Otherwise, a
        frame-string indicating that it is an EMPTY TFR.
    """
def detectEmptyTFR(frame: dict[str, object]) -> str {
    contents = frame['contents'] as dict[str, object];
    if 'records' in contents {
        records = contents['records'] as list[dict[str, object]];
        for x in records {
            if 'report_status' in x and x['report_status'] == 0 {
                continue;
            }
            if 'text' in x and x['text'] == '' {
                return ' [EMPTY TFR {}-{}]'.format(x['report_year'], x['report_number']);
            }
        }
    }
    return '';
}