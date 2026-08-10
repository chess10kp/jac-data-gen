"""Get code from GeoJSON feature."""
def get_feature_code(properties: dict[str, str], yearsuffix: str) -> str | None {
    code = None;
    if 'code' in properties {
        code = properties['code'];
    } elif ('lau1' + yearsuffix + 'cd') in properties {
        code = properties[('lau1' + yearsuffix + 'cd')];
    }
    return code;
}