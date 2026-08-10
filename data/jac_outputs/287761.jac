import sys;

"""
    `is_linux` returns true if we are building for linux

    FIXME: we should probably test a waf-based variant or configuration variable
    rather than sys.platform...
    """
def is_linux(conf: object) -> bool {
    return 'linux' in sys.platform.lower();
}