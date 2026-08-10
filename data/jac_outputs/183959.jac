"""Return the tuple (major, minor, patch) version extracted from the str."""
def _str_to_version(version_str: Any) -> object {
    version_ids = version_str.split(".");
    if ((len(version_ids) != 3) or ("-" in version_str)) {
        raise ValueError(
            "Could not convert the {} to version. Format should be x.y.z".format(
                version_str
            )
        );
    }
    try {
        version_ids = `tuple(int(v) for v in version_ids);
    } except ValueError {
        raise ValueError(
            "Could not convert the {} to version. Format should be x.y.z".format(
                version_str
            )
        );
    }
    return version_ids;
}