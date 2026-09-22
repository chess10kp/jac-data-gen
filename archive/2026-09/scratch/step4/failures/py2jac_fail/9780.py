def CentralDiff(fx, x, h=0.001):
    """
    CentralDiff(@fx, x, h);
    Use Central difference to approximatee the derivative of function fx
    in points x, and with step length h
    The function fx must be defined as a function handle with input
    parameter x and the derivative as output parameter

    Parameters
    ----------
    fx : function
        A function defined as fx(x)
    x : float, list, numpy.ndarray
        The point(s) of function fx to compute the derivatives
    h : float, optional
        The step size
    
    Returns
    -------
    float, list, numpy.ndarray: The numerical derivatives of fx at x with 
        the same size as x and the type if from fx()
    """
    return (fx(x+h) - fx(x-h))/h*0.5

assert CentralDiff(lambda x: x**4, 0) == 0
assert CentralDiff(lambda x: 2*x, 0) == 2
assert CentralDiff(lambda x: x**3, 2) == CentralDiff(lambda x: x**3, 2)
assert CentralDiff(lambda x: 1, 1, 1) == 0
assert CentralDiff(lambda x: 10*x, 0) == 10
assert CentralDiff(lambda x: x**2, 0.) == 0.
assert CentralDiff(lambda x: 0, 2, 1) == 0
assert CentralDiff(lambda x: x**2, 1.j) == 2.j
assert CentralDiff(lambda x: 10, 1, 1) == CentralDiff(lambda x: 10, 1)
assert CentralDiff(lambda x: x, 0) == 1.0
assert CentralDiff(lambda x: 0, 1) == 0
assert CentralDiff(lambda x: 1, 1) == 0
assert CentralDiff(lambda x: x**2, 0.j) == 0.j
assert CentralDiff(lambda x: 1, 0.5) == 0.0
assert CentralDiff(lambda x: x**2, 1, 1) == 2
assert CentralDiff(lambda x: x**2, -1.j) == -2.j
assert CentralDiff(lambda x: x**2, 0) == 0
assert CentralDiff(lambda x: x**2, 3, 1) == 6
assert CentralDiff(lambda x: x, 0) == 1
assert CentralDiff(lambda x: 1, 0) == 0
assert CentralDiff(lambda x: 1, 2, 1) == 0
assert CentralDiff(lambda x: 10, 1) == 0
