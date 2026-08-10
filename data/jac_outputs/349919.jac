"""
        Center a molecule using equally weighted points

        Parameters
            numpoints: Number of points
            refcoords: List of reference coordinates, with each set
                       a list of form [x,y,z] (list)
        Returns
            refcenter: Center of the set of points (list)
            relcoords: Moved refcoords relative to refcenter (list)
    """
def center(numpoints: Any, refcoords: Any) -> object {
    refcenter = [];
    relcoords = [];
    for i in range(3) {
        refcenter.append(0.0);
    }
    for i in range(numpoints) {
        refcenter[0] += refcoords[i][0];
        refcenter[1] += refcoords[i][1];
        refcenter[2] += refcoords[i][2];
    }
    for i in range(3) {
        refcenter[i] = refcenter[i] / numpoints;
    }
    for i in range(numpoints) {
        relcoords.append([]);
        relcoords[i].append((refcoords[i][0] - refcenter[0]));
        relcoords[i].append((refcoords[i][1] - refcenter[1]));
        relcoords[i].append((refcoords[i][2] - refcenter[2]));
    }
    return (refcenter, relcoords);
}