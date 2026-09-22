"""
# VARI: Visible Atmospherically Resistant Index
# VARI is the Visible Atmospherically Resistant Index, it was
# designed to introduce an atmospheric self-correction
# Gitelson A.A., Kaufman Y.J., Stark R., Stark R., Rundquist D., 2002.
# Novel algorithms for estimation of vegetation fraction
# Remote Sensing of Environment (80), pp76-87.
"""
def vari(blue: float, green: float, red: float) -> float {
    return (green - red) / ((green + red) - blue);
}