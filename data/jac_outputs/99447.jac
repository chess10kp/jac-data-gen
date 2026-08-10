"""
    Return a grid of 4 points inside given 3 points as a list.

    INPUT:

    - ``tripts`` -- A list of 3 lists of the form [x,y] where x and y are the
      Cartesian coordinates of a point.

    OUTPUT:

    A list of lists containing 4 points in following order:

    - 1. Barycenter of 3 input points.
    - 2,3,4. Barycenters of 1. with 3 different 2-subsets of input points
      respectively.

    EXAMPLES::

        sage: from sage.matroids import matroids_plot_helpers
        sage: points = matroids_plot_helpers.trigrid([[2,1],[4,5],[5,2]])
        sage: points
        [[3.6666666666666665, 2.6666666666666665],
         [3.222222222222222, 2.888888888888889],
         [4.222222222222222, 3.222222222222222],
         [3.5555555555555554, 1.8888888888888886]]

    .. NOTE::

            This method does NOT do any checks.

    """
def trigrid(tripts: list[list[float | int]]) -> list[list[float]] {
    pairs = [[0, 1], [1, 2], [0, 2]];
    cpt = [
        float(tripts[0][0] + tripts[1][0] + tripts[2][0]) / 3,
        float(tripts[0][1] + tripts[1][1] + tripts[2][1]) / 3
    ];
    grid = [cpt];
    for p in pairs {
        pt = [
            float(tripts[p[0]][0] + tripts[p[1]][0] + cpt[0]) / 3,
            float(tripts[p[0]][1] + tripts[p[1]][1] + cpt[1]) / 3
        ];
        grid.append(pt);
    }
    return grid;
}