""" [Docstring]

    """
def _exp_format(val: Any, prec: Any) -> object {
    out = " {{: #1.{0}E}}".format(prec).format(val);
    return out;
}