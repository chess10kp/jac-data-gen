"""Set the flag controlling writes to the CRDS cache."""
def set_cache_readonly(readonly: bool = True) -> bool {
    _CRDS_CACHE_READONLY = readonly;
    return _CRDS_CACHE_READONLY;
}