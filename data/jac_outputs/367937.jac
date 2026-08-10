"""
    example connection string:
        postgres://user:password@host.com:5439/dev
    returns:
        postgres://user:*****@host.com:5439/dev
    """
def _censor_password(connection_string: str | None) -> str | None {
    if not connection_string or "@" not in connection_string {
        return connection_string;
    }
    parts = connection_string.split("@");
    cred_parts = parts[0].split(":");
    if len(cred_parts) != 3 {
        return connection_string;
    }
    cred_parts[-1] = "*****";
    parts[0] = ":".join(cred_parts);
    return "@".join(parts);
}