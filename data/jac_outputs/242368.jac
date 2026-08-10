glob VERSION_MAJOR_MINOR_MULT = 100000;
glob VERSION_BUILD_MULT = 1000;
glob VERSION_PATCH_MULT = 10;

"""
Version Code is calculated based on the four version integers.
"""
def calculate_version_code(values_dict: dict[str, int], shift: int) -> int {
    try {
        major = values_dict['MAJOR'];
        minor = values_dict['MINOR'];
        build = values_dict['BUILD'];
        patch = values_dict['PATCH'];
        return (major + minor) * VERSION_MAJOR_MINOR_MULT + build * VERSION_BUILD_MULT + patch * VERSION_PATCH_MULT + shift;
    } except KeyError {
        return 0;
    }
}