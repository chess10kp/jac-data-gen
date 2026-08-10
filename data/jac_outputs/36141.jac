"""Returns the given dictionary as a string of space
     separated key/value pairs sorted by keys.
  """
def dict_to_str(`props: Any) -> object {
    ret = [];
    for k in sorted(`props.keys()) {
        ret += [k, `props[k]];
    }
    return " ".join(ret);
}