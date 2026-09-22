"""
  Takes one metric or a wildcard seriesList followed by a constant n.
  Draws only the metrics with a minimum value below n.

  Example:

  .. code-block:: none

    &target=minimumBelow(system.interface.eth*.packetsSent,1000)

  This would only display interfaces which at one point sent less than 1000 packets/min.
  """
def minimumBelow(requestContext: dict[str, str], seriesList: list[list[float]], n: float) -> list[list[float]] {
    return [series for series in seriesList if min(series) <= n];
}