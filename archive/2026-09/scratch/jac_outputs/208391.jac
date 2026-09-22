"""
    Coefficients of Yagi 2013 fits for multipolar
    $\bar{\lambda}_\ell = 2 k_\ell/(C^{2\ell+1} (2\ell-1)!!)$
    Tab.I (NS) http://arxiv.org/abs/1311.0872
    """
def Yagi13_fitcoefs(ell: Any) -> object {
    if (ell == 3) {
        c = [-1.15, 1.18, 0.0251, -0.00131, 2.52e-05];
    } elif (ell == 4) {
        c = [-2.45, 1.43, 0.0395, -0.00181, 2.8e-05];
    } else {
        c = [];
    }
    return c;
}