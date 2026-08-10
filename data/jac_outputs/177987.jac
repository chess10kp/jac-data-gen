"""Automatically chooses relevant unit for displaying a number of bytes."""
def _byte_str(num: int, unit: str = 'auto', precision: int = 2) -> str {
    abs_num = abs(num);
    if unit == 'auto' {
        if abs_num < 2.0 ** 10 {
            unit = 'KB';
        } elif abs_num < 2.0 ** 20 {
            unit = 'KB';
        } elif abs_num < 2.0 ** 30 {
            unit = 'MB';
        } elif abs_num < 2.0 ** 40 {
            unit = 'GB';
        } else {
            unit = 'TB';
        }
    }
    num_unit: float;
    if unit.lower().startswith('b') {
        num_unit = num;
    } elif unit.lower().startswith('k') {
        num_unit = num / (2.0 ** 10);
    } elif unit.lower().startswith('m') {
        num_unit = num / (2.0 ** 20);
    } elif unit.lower().startswith('g') {
        num_unit = num / (2.0 ** 30);
    } elif unit.lower().startswith('t') {
        num_unit = num / (2.0 ** 40);
    } else {
        raise ValueError('unknown num={!r} unit={!r}'.format(num, unit));
    }
    fmtstr = '{:.' + str(precision) + 'f}{}';
    return fmtstr.format(num_unit, unit);
}