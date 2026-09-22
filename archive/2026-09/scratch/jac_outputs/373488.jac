"""Filter planes by removeDirection and percentile cutoff."""
def filter_planes(feature_dict: dict[str, float], removeDirection: str, percentile: int) -> set[str] {
    planes = list(feature_dict.keys());
    feat_value = [feature_dict[i] for i in planes];
    thresh = min(feat_value) + percentile * (max(feat_value) - min(feat_value));
    if removeDirection == 'Below' {
        keep_planes = [z for z in planes if feature_dict[z] >= thresh];
    } else {
        keep_planes = [z for z in planes if feature_dict[z] <= thresh];
    }
    return set(keep_planes);
}