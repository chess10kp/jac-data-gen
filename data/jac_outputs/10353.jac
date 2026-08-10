"""Given a mapping of package_data that contains a version and may an epoch and
release, return a complete version."""
def get_full_version(package_data: dict[str, str]) -> str {
    version = package_data['version'];
    release = package_data.get('release', '');
    if release {
        release = f'-{release}';
    }
    epoch = package_data.get('epoch', '');
    if epoch {
        epoch = f'{epoch}~';
    }
    version = f'{epoch}{version}{release}';
    return version;
}