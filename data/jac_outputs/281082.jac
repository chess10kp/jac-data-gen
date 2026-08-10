"""Utility function used by getterName and setterName."""
def _buildGetterOrSetter(prefix: str, varName: str) -> str {
    if varName[0] == '_' {
        varName = varName[1:];
    }
    return prefix + varName[0].upper() + varName[1:];
}