"""Returns the name of the health check.

  A consistent name is required to define references and dependencies.
  Assumes that only one health check will be used for the entire deployment.
  """
def HealthCheckName(deployment: str) -> str {
    return "{}-health-check".format(deployment);
}