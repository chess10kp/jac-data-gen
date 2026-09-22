"""Return a description of an exception.

    This is a private function for use by safeDescription().
    """
def _descExc(reprOfWhat: str, err: Exception) -> str {
    try {
        return '(exception from repr(%s): %s: %s)' % (reprOfWhat, err.__class__.__name__, err);
    } except Exception {
        return '(exception from repr(%s))' % reprOfWhat;
    }
}