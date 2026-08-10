"""Validation for the ``font-stretch`` property."""
def font_stretch(keyword: str) -> bool {
    return keyword in (
        'ultra-condensed',
        'extra-condensed',
        'condensed',
        'semi-condensed',
        'normal',
        'semi-expanded',
        'expanded',
        'extra-expanded',
        'ultra-expanded'
    );
}