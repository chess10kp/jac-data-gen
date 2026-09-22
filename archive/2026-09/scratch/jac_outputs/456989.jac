"""The file extension used for ASCII (non-compiled) proxy source files."""
def getAsciiFileExtension(proxyType: str) -> str {
    return '.proxy' if proxyType == 'Proxymeshes' else '.mhclo';
}