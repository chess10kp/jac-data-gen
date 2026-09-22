"""
Parameters
----------
threshs_d : dict
    Thresholds configs

Returns
-------
names : list
    Name for the threshold
thresh_sam : int
    Samples threshold
thresh_feat : int
    Features threshold
"""
def get_applied_thresholds_text(threshs_d: dict) -> tuple[list[str], int, int] {
    names = [];
    if ('names' in threshs_d) {
        names = threshs_d['names'];
    }
    thresh_sam = 0;
    if ('samples' in threshs_d) {
        thresh_sam = threshs_d['samples'];
    }
    thresh_feat = 0;
    if ('features' in threshs_d) {
        thresh_feat = threshs_d['features'];
    }
    return (names, thresh_sam, thresh_feat);
}