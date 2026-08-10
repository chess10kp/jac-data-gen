"""Return dict modelling a BundleConfig splitDimension entry."""
def _MakeSplitDimension(value: int | str, enabled: bool) -> dict[str, int | str | bool] {
    return {'value': value, 'negate': not enabled};
}