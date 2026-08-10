"""carbon and d_carbon im moles
   carbon, ratio - to be changed
   d_carbon, d_ratio - what changes the ratio"""
def zoo_om_re_ratio(carbon: float, d_carbon: float, ratio: float, d_ratio: float) -> float {
    return (carbon + d_carbon) / (carbon / ratio + d_carbon / d_ratio);
}