"""
    return a template metric
    """
def make_metric(name: Any) -> object {
    return {
        "type": "Metric",
        "name": name,
        "value": "",
        "units": "",
        "rating": "",
        "notes": "",
        "comment": ""
    };
}