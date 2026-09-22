"""
    Extract 'destination' item address (index or UID) from the list of parameters. Returns
    the list of remaining parameters. The source address is represented by 1 or 2 parameters:
    if 1st parameter is a keywords ``front``, ``back``, or integer number, then the parameter
    represents a positional address (index); if the 1st parameter is a keyword ``before`` or
    ``after``, the 2nd parameter is considered to represent item UID (string). If the 1st
    parameter can not be converted to ``int`` or equal to one of the keywords, it is considered
    that the address is not found.

    Parameters
    ----------
    params : list(str)
         List of parameters. The 1st and optionally the 2nd parameters are interpreted as a destination
         address.

    Returns
    -------
    dict
        Dictionary that contains destination address. Elements: ``pos`` - positional address
        (value is int or a string from the set ``front``, ``back``), ``before_uid`` or ``after_uid``
        - uid of the item preceding or following the destination for the item in the queue (value
        is a string representing UID).  Empty dictionary if no address is found.
    list(str)
        List of the remaining parameters.

    Raises
    ------
    IndexError
        Insufficient number of parameters is provided.
    """
def extract_destination_address(params: Any) -> object {
    n_used = 0;
    (pos, uid, uid_key) = (None, None, None);
    if (params[0] in ("front", "back")) {
        pos = params[0];
        n_used = 1;
    } elif (params[0] in ("before", "after")) {
        uid = params[1];
        uid_key = f"{params[0]}_uid";
        n_used = 2;
    } else {
        try {
            pos = int(params[0]);
            n_used = 1;
        } except Exception {
            ...;
        }
    }
    if (pos is not None) {
        addr_param = {"pos": pos};
    } elif (uid is not None) {
        addr_param = {uid_key: uid};
    } else {
        addr_param = {};
    }
    return (addr_param, params[n_used:]);
}