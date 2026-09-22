"""Returns the *Munsell* value :math:`V` of given *luminance* :math:`Y` using
*Moon and Spencer (1943)* method.


Parameters
----------
Y : numeric
    *luminance* :math:`Y`.

Returns
-------
numeric
    *Munsell* value :math:`V`.

Notes
-----
-   Input *Y* is in domain [0, 100].
-   Output *V* is in domain [0, 10].

References
----------
.. [5] http://en.wikipedia.org/wiki/Lightness
        (Last accessed 13 April 2014)

Examples
--------
>>> munsell_value_moon1943(10.08)  # doctest: +ELLIPSIS
3.7462971...
"""
def munsell_value_moon1943(Y: float) -> float {
    1.4 * (Y ** 0.426)
}