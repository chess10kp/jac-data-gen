"""
Compute suma DL target based on lpp source name.

When the location is empty, set the location path to
    /usr/sys/inst.images
Check if a lpp_source NIM resource already exist and check the path is
    the same
When the location is not a path, check that a NIM lpp_source
    corresponding to the location value exists, and returns the
    location path of this NIM ressource.

return:
    return code : 0 - OK
                  1 - if error
    dl_target value or msg in case of error
"""
def compute_dl_target(location: str, lpp_source: str, nim_lpp_sources: dict[str, str]) -> tuple[int, str] {
    if not location or not location.strip() {
        loc = "/usr/sys/inst.images";
    } else {
        loc = location.rstrip('/');
    }
    if loc[0] == '/' {
        dl_target = "{}/{}".format(loc, lpp_source);
        if lpp_source in nim_lpp_sources and nim_lpp_sources[lpp_source] != dl_target {
            return (
                1,
                "SUMA Error: lpp source location mismatch. It already "
                "exists a lpp source '{}' with a location different as '{}'".format(
                    lpp_source, dl_target
                )
            );
        }
    } else {
        if loc not in nim_lpp_sources {
            return (1, "SUMA Error: lpp_source: '{}' does not exist".format(loc));
        }
        dl_target = nim_lpp_sources[loc];
    }
    return (0, dl_target);
}