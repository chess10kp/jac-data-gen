"""
    Return sensitive attributes in appropriate format
    """
def _get_sensitive_attibutes(known_sensitive_features: list[str], features: list[str]) -> list[list[str]] {
    _sensitive_attributes: dict[str, list[str]] = {};
    for _column in features {
        if "_" in _column and _column.split("_")[0] in known_sensitive_features {
            prefix = _column.split("_")[0];
            if prefix not in _sensitive_attributes {
                _sensitive_attributes[prefix] = [_column];
            } else {
                _sensitive_attributes[prefix].append(_column);
            }
        } elif _column in known_sensitive_features {
            if _column not in _sensitive_attributes {
                _sensitive_attributes[_column] = [_column];
            } else {
                _sensitive_attributes[_column].append(_column);
            }
        }
    }
    return [_sensitive_attributes[key] for key in _sensitive_attributes];
}