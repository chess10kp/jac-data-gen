""" Converts grams to kilograms if grams are greater than 1,000. """
def metric(grams: int | str | float) -> str {
    grams = int(grams);
    if grams >= 1000 {
        kilograms = grams / 1000.0;
        if not grams % 1000 {
            kilograms = int(kilograms);
        }
        return '%s %s' % (str(kilograms), 'kg');
    }
    return '%s %s' % (str(grams), 'g');
}