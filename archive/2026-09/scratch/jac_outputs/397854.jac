"""Returns True if f should be checked for integrity."""
def should_check_integrity(f: str) -> bool {
    return f not in ('README.md', 'TRAINING_LOG', 'checksum.md5', 'data')
        and not f.startswith('.');
}