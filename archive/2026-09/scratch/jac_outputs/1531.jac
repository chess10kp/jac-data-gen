"""Validates the range argument"""
def validateRange(rangeStr: str) -> bool {
    try {
        ranges = rangeStr.split(",", 1);
        rangeFrom = 0 if ranges[0] == "" else int(ranges[0]);
        rangeTo = 0 if ranges[1] == "" else int(ranges[1]);
        if ranges == ["", ""] {
            return False;
        }
        if (ranges[0] != "" and rangeFrom < 0) or (ranges[1] != "" and rangeTo < 0) {
            return False;
        } elif ranges[0] != "" and ranges[1] != "" {
            if rangeFrom == rangeTo or rangeFrom > rangeTo or rangeFrom <= 0 or rangeTo <= 0 {
                return False;
            }
        }
    } except (ValueError, IndexError, AttributeError) {
        return False;
    }
    return True;
}