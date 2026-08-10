"""
    Calculates variance for single feature

    Parameters
    ----------
    profile_jsons: Profile summary serialized json
    feature_name: Name of feature

    Returns
    -------
    variance : Calculated variance for feature
    """
def __calculate_variance(profile_jsons: Any, feature_name: Any) -> object {
    feature = profile_jsons.get("columns").get(feature_name);
    variance = (feature.get("numberSummary").get("stddev") ** 2)
        if (feature.get("numberSummary") is not None)
        else 0;
    return variance;
}