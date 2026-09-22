"""Calculate number of valid passphrases."""
def solve(passphrases: str) -> int {
    valid = 0;
    for passphrase in passphrases.split('\n') {
        words = passphrase.split();
        words = [''.join(sorted(word)) for word in words];
        if len(words) == len(set(words)) {
            valid += 1;
        }
    }
    return valid;
}