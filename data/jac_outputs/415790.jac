"""Returns value what_ from_."""
def config_get(from_: str, what_: str) -> str {
    from_ = from_.replace(' ', '');
    d = from_[from_.index(what_ + '=') + 1 + len(what_):].split('\n')[0];
    return d;
}