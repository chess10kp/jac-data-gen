"""[summary]

    Arguments:
        record {[type]} -- [description]

    Returns:
        bool -- [description]
    """
def __is_quote_record_valid(record: Any) -> bool {
    if ("fields" not in record) {
        print("Quote record has no fields");
        return False;
    }
    if ("Quote" not in record["fields"]) {
        print("Quote record has no 'Quote' field");
        return False;
    }
    if ("Source" not in record["fields"]) {
        print("Quote record has no 'Source' field");
        return False;
    }
    return True;
}