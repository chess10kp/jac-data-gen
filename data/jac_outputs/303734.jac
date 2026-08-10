"""Criteria by which to filter concepts from the lattice"""
def _stability_filter(concept: list[float], stability_thresh: list[float]) -> bool {
    return concept[2] > stability_thresh[0] or concept[3] > stability_thresh[1];
}