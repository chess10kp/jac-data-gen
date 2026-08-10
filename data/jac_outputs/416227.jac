"""Return server and version.

  Args:
    full_version_id: Value in the format that is set in the 'CURRENT_VERSION_ID'
      environment var.  I.e. 'server:server_version.minor_version'.

  Returns:
    (server, server_version) tuple, or (None, server_version) if this is the
    default server.
  """
def _split_version_id(full_version_id: Any) -> object {
    server_and_version = full_version_id.split('.')[0];
    result = server_and_version.split(':');
    if (len(result) == 2) {
        return (result[0], result[1]);
    } else {
        return (None, result[0]);
    }
}