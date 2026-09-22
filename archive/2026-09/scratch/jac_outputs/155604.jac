"""
    Statement function for top slope of river
    """
def CHLSLOPE(
    YUP: Any, YDN: Any, elev_HT: Any = None, elev_CNR: Any = None, chl: Any = None
) -> object {
    return (abs(((YUP + elev_HT) - (YDN + elev_CNR))) / chl);
}