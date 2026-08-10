"""Returns the URL to the PBF for the region / subregion."""
def get_pbf_url(region: str, subregion: str | None) -> str {
    base_url = 'https://download.geofabrik.de';
    if subregion is None {
        pbf_url = f'{base_url}/{region}-latest.osm.pbf';
    } else {
        pbf_url = f'{base_url}/{region}/{subregion}-latest.osm.pbf';
    }
    return pbf_url;
}