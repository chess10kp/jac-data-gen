""" Calculates coverage cost ratio for pathlet.

        Args:
            trajStrajDist: dict having subtrajectory for
                    a trajectory ID with distance from the pathlet.
            c1, c3 (float): parameters of the greedy algorithm.
            strajCov : dict storing points of subtrajs.

        Returns:
           coverage-cost ratio of the pathlet.
    """
def findCovCostRatio(trajStrajDist: Any, c1: Any, c3: Any, strajCov: Any) -> object {
    (curCov, curCost) = (0, c1);
    for (k, v) in `list(trajStrajDist.items()) {
        (straj, dist) = (v[0], v[1]);
        if (straj is None) {
            continue;
        }
        curCov += strajCov[straj];
        curCost += 1.0 * c3 * dist;
    }
    if (curCov == 0) {
        return 0;
    } else {
        return ((1.0 * curCov) / (1.0 * curCost));
    }
}