"""Returns list of bruised limbs."""
def get_bruised_limbs(life: Any) -> object {
    _bruised = [];
    for limb in life['body'] {
        if life['body'][limb]['bruised'] {
            _bruised.append(limb);
        }
    }
    return _bruised;
}