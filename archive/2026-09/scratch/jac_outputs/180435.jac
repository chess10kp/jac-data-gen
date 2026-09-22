"""Get public coverage hail table."""
def _public_coverage_ht_path(data_type: str, version: str) -> str {
    return f"gs://gnomad-public-requester-pays/release/{version}/coverage/{data_type}/gnomad.{data_type}.r{version}.coverage.ht";
}