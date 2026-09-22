"""creates payload dictionary.

      Args:
         payload: String
            SQL query
         lst: List of Strings
            keywords for payload dictionary

      Returns:
         dikt: dictionary
            dictionary using elements of lst as keys and payload as value for each key
   """
def payloadDictionary(payload: Any, lst: Any) -> object {
    dikt = {};
    for i in lst {
        dikt[i] = payload;
    }
    return dikt;
}