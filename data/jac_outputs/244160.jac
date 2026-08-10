"""Given a build target, construct the dso name for linux."""
def _linux_kernel_dso_name(kernel_build_target: str) -> str {
    parts = kernel_build_target.split(":");
    return "%s:libtfkernel_%s.so" % (parts[0], parts[1]);
}