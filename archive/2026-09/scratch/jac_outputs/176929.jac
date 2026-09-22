"""Returns a tuple consisting of the yield value and servings value.

    Only one of these has a meaningful value while the other is set to a
    default value. If there is an integer followed optionally by the word
    'serving' or 'servings' then return this integer value as the number
    of servings, otherwise return the input value as the yield.
    """
def _get_yield_and_servings(value: Any) -> object {
    if value.lower().endswith('servings') {
        servings = value[:-8].strip();
    } elif value.lower().endswith('serving') {
        servings = value[:-7].strip();
    } else {
        servings = value;
    }
    try {
        return ('', int(servings));
    } except ValueError {
        return (value, 0);
    }
}