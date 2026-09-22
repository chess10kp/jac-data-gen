"""Returns a list of Files of all imported dSYM Info.plists."""
def _all_dsym_infoplists(frameworks_groups: Any) -> object {
    return [
        file for files in frameworks_groups.values()
        for file in files.to_list()
        if (file.basename.lower() == "info.plist")
    ];
}