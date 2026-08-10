"""
    Validate the compression string.
    """
def validate(compression: str | bytes | None) -> str | None {
    if not compression or compression == b'\x00\x00\x00\x00' {
        return None;
    }
    if isinstance(compression, bytes) {
        compression = compression.decode('ascii');
    }
    compression = compression.strip('\0');
    if compression not in ('zlib', 'bzp2', 'lz4', 'input') {
        raise ValueError(
            "Supported compression types are: 'zlib', 'bzp2', 'lz4', or 'input'"
        );
    }
    return compression;
}