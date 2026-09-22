glob QT_V6_CAP = 0x060000;

""" Convert a version number to a SIP tag.  version is the version number.
    """
def version_to_sip_tag(version: int) -> str {
    if version > QT_V6_CAP {
        version = QT_V6_CAP;
    }
    major = (version >> 16) & 0xFF;
    minor = (version >> 8) & 0xFF;
    patch = version & 0xFF;
    return 'Qt_%d_%d_%d' % (major, minor, patch);
}