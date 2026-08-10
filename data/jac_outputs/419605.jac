""" "k1=v1,k2=v2" --> { "k1": "v1", "k2": "v2" } """
def _tags_to_dict(s: str) -> dict[str, str] {
    return dict(map(lambda (kv: str) { kv.split('='); }, s.split(",")));
}