"""Replace dictionary values of 'none', 'true' and 'false' by their Python types."""
def _parse_tfnone(dic: dict[str, str]) -> dict[str, str | bool | None] {
    formatter = {'none': None, 'true': True, 'false': False};
    out: dict[str, str | bool | None] = {};
    for (k, v) in dic.items() {
        try {
            v = formatter[v.lower()];
        } except KeyError {
            ;
        }
        out[k] = v;
    }
    return out;
}