"""Computes the (monthly) mean temperature at the glacier terminus,
following section 2.1.2 of Marzeion et. al., 2012. The input temperature
is scaled by the given temperature gradient and the elevation difference
between reference altitude and the glacier terminus elevation.

Parameters
----------
temp : netCDF4 variable
    monthly mean climatological temperature (degC)
temp_grad : netCDF4 variable or float
    temperature lapse rate [degC per m of elevation change]
ref_hgt : float
    reference elevation for climatological temperature [m asl.]
terminus_hgt : float
    elevation of the glacier terminus (m asl.)
temp_anomaly : netCDF4 variable or float, optional
    monthly mean temperature anomaly, default 0

Returns
-------
netCDF4 variable
    monthly mean temperature at the glacier terminus [degC]
"""
def _compute_temp_terminus(
    temp: float, temp_grad: float, ref_hgt: float, terminus_hgt: float, temp_anomaly: float = 0
) -> float {
    return temp + temp_grad * (terminus_hgt - ref_hgt) + temp_anomaly;
}