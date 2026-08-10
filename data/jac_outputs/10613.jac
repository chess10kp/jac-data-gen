"""Performs version comparison to report if host is already at required
    version

    Args:
        version_req: Version that want to be at
        current_version: Version that host is currently at
    Returns:
        True if current_version >= version_req
        False otherwise
    Raises:
        ValueError: if version is in unsupported format
"""
def compare_version(version_req: str | None, current_version: str | None) -> bool {
    if current_version == None {
        return False;
    }
    if version_req == None {
        return True;
    }
    if current_version == version_req {
        return True;
    }
    current_vers = current_version.split(".");
    req_vers = version_req.split(".");
    num_loops = len(current_vers);
    if len(req_vers) < num_loops {
        num_loops = len(req_vers);
    }
    for index in range(num_loops) {
        if int(current_vers[index]) < int(req_vers[index]) {
            return False;
        } elif int(current_vers[index]) > int(req_vers[index]) {
            return True;
        }
    }
    if len(current_vers) > len(req_vers) {
        return True;
    } elif len(req_vers) > len(current_vers) {
        return False;
    } else {
        return True;
    }
}