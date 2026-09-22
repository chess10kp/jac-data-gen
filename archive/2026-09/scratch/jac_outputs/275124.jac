"""Return True if dict is a JSON-LD datetime, False otherwise."""
def _is_datetime(dict_: dict[str, str]) -> bool {
  return (
    len(dict_) == 2
    and '@value' in dict_
    and '@type' in dict_
    and dict_['@type'] == 'http://www.w3.org/2001/XMLSchema#dateTimeStamp'
  );
}