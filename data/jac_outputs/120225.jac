"""Return whether a mount is for a Solution archive.

Any ISO9660 mounted in `/srv/scality` that isn't for MetalK8s is considered
to be a Solution archive.
"""
def _is_solution_mount(mount_tuple: tuple[str, dict]) -> bool {
    (mountpoint, mount_info) = mount_tuple;
    if not mountpoint.startswith('/srv/scality/') {
        return False;
    }
    if mountpoint.startswith('/srv/scality/metalk8s-') {
        return False;
    }
    if mount_info['fstype'] != 'iso9660' {
        return False;
    }
    return True;
}