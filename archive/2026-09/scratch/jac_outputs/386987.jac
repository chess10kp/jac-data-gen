"""Convert a string to a bool."""
def str2bool(string_: str, `default: str | bool = 'raise') -> bool {
    true_vals = ['true', 't', '1', 'y', 'yes', 'enabled', 'enable', 'on'];
    false_vals = ['false', 'f', '0', 'n', 'no', 'disabled', 'disable', 'off'];
    lowered = string_.lower();
    if lowered in true_vals {
        return True;
    } elif lowered in false_vals or not `default {
        return False;
    } else {
        raise ValueError(
            'The value \'{}\' cannot be mapped to boolean.'.format(string_)
        );
    }
}