"""
    See explantion in C_redox_Estep_semiinfinite()
    Kristian B. Knudsen (kknu@berkeley.edu || Kristianbknudsen@gmail.com)
    """
def Varsigma(D_ox: float, D_red: float) -> float {
    (D_ox / D_red) ** (1 / 2)
}