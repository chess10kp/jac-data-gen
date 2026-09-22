"""Write a message."""
def message(name: Any, pval: Any, alpha: Any = 0.01) -> object {
    if (pval < alpha) {
        return '{0} can be rejected (pval <= {1:.2g})'.format(name, pval);
    } else {
        return '{0} cannot be rejected (pval = {1:.2g})'.format(name, pval);
    }
}