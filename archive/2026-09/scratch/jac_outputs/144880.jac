"""
    returns a list of r1 and r2 values that satisfies:
    r1/r2 = area2/area1 with the constraints:
    r1 <= Area_max/area1 and r2 <= Area_max/area2
    r1 and r2 corresponds to the supercell sizes of the 2 interfaces
    that align them
    """
def get_r_list(area1: Any, area2: Any, max_area: Any, tol: Any = 0.02) -> object {
    r_list = [];
    rmax1 = int((max_area / area1));
    rmax2 = int((max_area / area2));
    print('rmax1, rmax2: {0}, {1}\n'.format(rmax1, rmax2));
    for r1 in range(1, (rmax1 + 1)) {
        for r2 in range(1, (rmax2 + 1)) {
            if ((abs(((float(r1) * area1) - (float(r2) * area2))) / max_area) <= tol) {
                r_list.append([r1, r2]);
            }
        }
    }
    return r_list;
}