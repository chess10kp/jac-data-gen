def get_thresholds(threshs_d: dict) -> tuple[list, int, int] {
    names = [];
    if 'names' in threshs_d {
        names = threshs_d['names'];
    }
    thresh_sam = 0;
    if 'samples' in threshs_d {
        thresh_sam = threshs_d['samples'];
    }
    thresh_feat = 0;
    if 'features' in threshs_d {
        thresh_feat = threshs_d['features'];
    }
    return (names, thresh_sam, thresh_feat);
}