"""Get the specified build property from the build properties dictionary.

Example property names are Chromium OS Version ('branch'), Chromium OS
Version ('buildspec_version'), and GIT Revision ('git_revision').
"""
def _GetBuildProperty(build_properties: list[list[str]], property_name: str) -> str | None {
    property_value: str | None = None;
    for property_list in build_properties {
        if property_name in property_list {
            property_value = property_list[1];
            break;
        }
    } else {
        print(("  Warning: Build properties has no %s property." % property_name));
    }
    return property_value;
}