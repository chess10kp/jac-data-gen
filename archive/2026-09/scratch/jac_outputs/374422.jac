"""
Prepares a qualification object from an expression string.
Examples:
    location in US,CA,GB
    location not_in US-CA,US-MA
    hits_approved > 500
    percent_approved > 95
"""
def prepare_qualification(qual: str) -> dict {
    _QUAL_IDS = {
        "location": '00000000000000000071',
        "hits_approved": '00000000000000000040',
        "percent_approved": '000000000000000000L0'
    };
    _COMPARATORS = {
        ">": "GreaterThan",
        "=": "GreaterThan",
        "<": "LessThan",
        "in": "In",
        "not_in": "NotIn"
    };
    parts = qual.split(' ');
    if len(parts) != 3 or parts[1] not in _COMPARATORS {
        raise ValueError("Invalid qualification specifier: {}".format(qual));
    }
    (qual_id, comparator, value) = parts;
    if qual_id == "location" {
        assert comparator in ["in", "not_in"], f"When using a location qualification, use 'in' or 'not_in'. Got {qual}.";
        locations = value.split(",");
        locale_values = [];
        for location in locations {
            loc_parts = location.split("-", 1);
            if len(loc_parts) == 1 {
                locale_values.append({"Country": loc_parts[0]});
            } else {
                locale_values.append({"Country": loc_parts[0], "Subdivision": loc_parts[1]});
            }
        }
        return {
            "QualificationTypeId": _QUAL_IDS.get(qual_id, qual_id),
            "Comparator": _COMPARATORS[comparator],
            "LocaleValues": locale_values
        };
    }
    return {
        "QualificationTypeId": _QUAL_IDS.get(qual_id, qual_id),
        "Comparator": _COMPARATORS[comparator],
        "IntegerValues": [int(value)]
    };
}