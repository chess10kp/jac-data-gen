"""
    Return base dynamic hasher names for each entry in HMAC_KEYS (we need to
    create one hasher class for each key). Names are sorted to make sure
    the HMAC_KEYS are tested in the correct order and the first one is always
    the first hasher name returned.
    """
def get_dynamic_hasher_names(HMAC_KEYS: Any) -> object {
    algo_name = lambda (hmac_id: Any) { 'bcrypt{0}'.format(
        hmac_id.replace('-', '_')
    ); };
    return [algo_name(key) for key in sorted(HMAC_KEYS.keys(), reverse=True)];
}