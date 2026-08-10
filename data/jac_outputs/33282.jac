"""
    Reverses ``encode_topic_name``.

    :param encoded: the encoded SNS topic name
    :return: the decoded channel name
    """
def decode_topic_name(encoded: str) -> str {
    decoded = encoded;
    decoded = decoded.replace("_WCD_", "*");
    decoded = decoded.replace("_FWS_", "/");
    decoded = decoded.replace("_DOT_", ".");
    decoded = decoded.replace("_COL_", ":");
    decoded = decoded.replace("_LT_", "<");
    decoded = decoded.replace("_GT_", ">");
    return decoded;
}