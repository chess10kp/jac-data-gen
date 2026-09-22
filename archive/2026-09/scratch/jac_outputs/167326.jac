"""
    (theta')^(-1) (y) = alpha * y / (1 - |y|)
    Alternatives:
        In Baus et al 2013      b(beta) = (theta')^(-1) (beta*eta) [eq 12]
        In Nikolova et al 2013  b(y)    = (theta')^(-1) (y)        [eq 12]
        In Nikolova et al 2014  xi(t)   = (theta')^(-1) (t)        [eq 4]
    Baus et al 2013, table 1, Theta_2 with b(beta) given in table 2.
    Nikolova et al 2014, table 1, theta_2.
    """
def d_theta_inv(y: float, alpha: float) -> float {
    assert -1 < y < 1 and alpha > 0;
    abs_y = y if y >= 0.0 else -y;
    return alpha * y / (1.0 - abs_y);
}