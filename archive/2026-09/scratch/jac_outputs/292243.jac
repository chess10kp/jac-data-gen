import numpy;

"""Spectral test to determine potential snow

Uses the 9.85C (283K) threshold defined in Zhu, Woodcock 2015

Parameters
----------
ndsi: ndarray
green: ndarray
nir: ndarray
tirs1: ndarray

Output
------
ndarray:
    boolean, True is potential snow
"""
def potential_snow_layer(ndsi: numpy.ndarray, green: numpy.ndarray, nir: numpy.ndarray, tirs1: numpy.ndarray) -> numpy.ndarray {
    return (ndsi > 0.15) & (tirs1 < 9.85) & (nir > 0.11) & (green > 0.1);
}