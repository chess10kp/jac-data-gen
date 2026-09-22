"""Combine a Curation metadata and a Canvas metadata based Curation search result."""
def combine(cr1: dict[str, bool], cr2: dict[str, bool]) -> dict[str, bool] {
    if cr1['curationHit'] {
        has_cur = cr1;
        has_can = cr2;
    } else {
        has_cur = cr2;
        has_can = cr1;
    }
    has_cur['canvasHit'] = has_can['canvasHit'];
    has_cur
}