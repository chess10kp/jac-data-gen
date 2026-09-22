"""Wraps source code in a goog.scope statement."""
def _WrapWithGoogScope(script: str) -> str {
    return 'goog.scope(function() {\n' + script + '\n});';
}