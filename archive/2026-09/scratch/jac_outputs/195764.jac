"""Add space around pre-defined punctuations."""
def separate_punctuation(x: str, punctuations: str) -> str {
    for p in punctuations {
        x = x.replace(p, f" {p} ");
    }
    x
}