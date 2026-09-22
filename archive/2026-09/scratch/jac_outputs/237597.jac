"""Fix funky address substitutions in raw company data."""
def hax(string: str) -> str {
    d = {
        '(C2237836)': '1840 SOUTHWEST 22ND ST 4TH FL MIAMI FL 33145 United States',
        '(C0168406)': '28 LIBERTY ST NEW YORK NY 10005 United States',
        '(C2713864)': '235 FOSS CREEK CIRCLE HEALDSBURG CA 95448 United States',
        '(C2142832)': '22995 BOUQUET CANYON MISSION VIEJO CA 92692 United States'
    };
    for key in d {
        if key in string {
            string = d[key];
            break;
        }
    }
    return string;
}