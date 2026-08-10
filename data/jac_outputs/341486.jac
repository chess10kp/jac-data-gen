"""
	Determines if redrawn points are counter clockwise in cross-section

	Parameters
	----------
	x : x-coordinates of cross-section
	y : y-coordinates of cross-section
	xm : x[i-1]
	ym : y[i-1]
	nx : new x-coordinate
	ny : new y-coordinate

	Returns
	-------
	ccw : Array of bools indicating which new points are counter clockwise
	"""
def ccw(x: float, y: float, xm: float, ym: float, nx: float, ny: float) -> bool {
    return (x - xm) * (ny - ym) > (y - ym) * (nx - xm);
}