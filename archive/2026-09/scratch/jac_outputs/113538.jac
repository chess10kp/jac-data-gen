"""convert e.g., 3 to 1e-3 where 3 is the
    number of decimal places"""
def precision2eml(precision: int) -> str {
    return '1e-{}'.format(precision);
}