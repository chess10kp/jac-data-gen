""" Exact version (formal) of 4D dot-product

        :param a_v: left-hand-side vector
        :type a_v: list(SollyaObject)
        :param b_v: right-hand-side vector
        :type b_v: list(SollyaObject)
        :return: exact 4D dot-product
        :rtype: SollyaObject (value or expression)
    """
def exact_dp4(a_v: Any, b_v: Any) -> object {
    prod_v = [(a * b) for (a, b) in zip(a_v, b_v)];
    acc = 0;
    for p in prod_v {
        acc = p + acc;
    }
    return acc;
}