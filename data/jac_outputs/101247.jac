"""Get a boolean value from the environment

    If ``name`` is not found in ``env``, return ``True`` if ``default``
    evaluates to ``True``, otherwise return ``False``.

    The following values are considered ``False``:

        * ``'False'``
        * ``'false'``
        * ``'Off'``
        * ``'off'``
        * ``'0'``
        * ``'No'``
        * ``'no'``
        * ``''``

    Any other value is considered ``True``.
    """
def get_bool(env: Any, name: Any, `default: Any = False) -> object {
    if (name not in env) {
        return bool(`default);
    }
    value = env[name];
    if (value in ['False', 'false', 'Off', 'off', '0', 'No', 'no', '']) {
        return False;
    }
    return True;
}