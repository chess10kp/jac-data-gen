"""Fills in the given template dictionary with top improvements.

  Args:
    recent_anomalies: A list of Anomaly entities sorted from large to small.
    num_to_show: The number of improvements to return.

  Returns:
    A list of top improvement Anomaly entities, in decreasing order.
  """
def _TopImprovements(recent_anomalies: Any, num_to_show: Any) -> object {
    improvements = [
        a
        for a in recent_anomalies
        if a.is_improvement
    ];
    return improvements[:num_to_show];
}