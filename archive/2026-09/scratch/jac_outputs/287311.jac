glob UINT32_MAX = (1 << 32) - 1;

"""Validate ASN ranges provided are valid and properly formatted."""
def validate_asn_ranges(ranges: list[list[int]]) -> list[str] {
    errors = [];
    for asn_range in ranges {
        if not isinstance(asn_range, list) {
            errors.append("Invalid range: must be a list");
        } elif len(asn_range) != 2 {
            errors.append("Invalid range: must be a list of 2 members");
        } elif any(not isinstance(r, int) for r in asn_range) {
            errors.append("Invalid range: Expected integer values");
        } elif asn_range[1] <= asn_range[0] {
            errors.append("Invalid range: 2nd element must be bigger than 1st");
        } elif asn_range[0] < 1 or asn_range[1] > UINT32_MAX {
            errors.append(
                "Invalid range: must be a valid range between 1 and 4294967295"
            );
        }
    }
    return errors;
}