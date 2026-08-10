"""Get the soundex code for the string"""
def getSoundex(name: str) -> str {
    name = name.upper();
    soundex = "";
    soundex += name[0];
    dictionary = {
        "BFPV": "1",
        "CGJKQSXZ": "2",
        "DT": "3",
        "L": "4",
        "MN": "5",
        "R": "6",
        "AEIOUHWY": "."
    };
    for char in name[1:] {
        for key in dictionary.keys() {
            if char in key {
                code = dictionary[key];
                if code != soundex[-1] {
                    soundex += code;
                }
            }
        }
    }
    soundex = soundex.replace(".", "");
    soundex = soundex[:4].ljust(4, "0");
    return soundex;
}