"""Linear reconstruction with linear weights.  This reconstructs u_{i+1/2}
    given cell averages \\bar{u}_i at each neighboring location.

    See (2.14) in `High Order Weighted Essentially Nonoscillatory Schemes for
    Convection Dominated Problems'.
    """
def LinearReconstruct(u_stencil: tuple[float, float, float, float, float]) -> float {
    (uim2, uim1, ui, uip1, uip2) = u_stencil;
    return uim2 / 30 - (13 * uim1) / 60 + 47 * (ui / 60) + 9 * (uip1 / 20) - uip2 / 20;
}