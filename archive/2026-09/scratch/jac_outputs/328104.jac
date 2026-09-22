"""Calculate volumetric efficency for a given pump's typical number.

The polynomial has been calculated applaying the curve fitting at nodes
cappa       .2 .3 .4 .5 .6 .7 .8 .9 1.0 1.1 1.2
eta_hyd     .940 .948 .953 .956 .957 .958 .959 .960 .961 .962 .963
weights     ones(cappa)
n           5

:param cappa (float): typical number
:return eta_vol (float): volumetric efficency
"""
def efficency_vol_poly(cappa: float) -> float {
    coef = [0.907, 0.236, -0.433, 0.378, -0.144, 0.016];
    return sum(val * cappa ** idx for (idx, val) in enumerate(coef));
}