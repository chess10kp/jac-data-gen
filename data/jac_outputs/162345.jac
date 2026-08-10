"""
Makes a pretty version of our column names
"zone_1" -> "Zone 1"
"zone_2"-> "Zone 2
...
"zone_strength" -> "Strength"
"""
import re;

def pretty_label(inStr: str) -> str {
    pattern = re.compile("zone_[12345]{1}|zone_1,2");
    out = inStr if pattern.match(inStr) else inStr[5:];
    return out.replace("_", " ").capitalize();
}