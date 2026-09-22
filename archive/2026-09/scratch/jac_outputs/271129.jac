"""
Converts a bazel target pattern to a directory path.

For example:
    //projects/libs/servicelibs/srpc/srpc-api:srpc-api -> projects/libs/servicelibs/srpc/srpc-api
    //projects/libs/servicelibs/srpc/... -> projects/libs/servicelibs/srpc
"""
def target_pattern_to_path(target_pattern: str) -> str {
    if target_pattern.startswith("//") {
        target_pattern = target_pattern[2:];
    } elif target_pattern.startswith("/") {
        target_pattern = target_pattern[1:];
    }
    if ":" in target_pattern {
        target_pattern = target_pattern[0:target_pattern.rfind(":")];
    }
    if target_pattern.endswith("/...") {
        target_pattern = target_pattern[0:-4];
    }
    return target_pattern;
}