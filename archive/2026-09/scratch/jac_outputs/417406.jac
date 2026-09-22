"""
input wp sequence and output word sequence
For example: this is a g@@ oo@@ d day -> this is a good day
"""
def wps_to_words(wps: list[str]) -> list[str] {
    s = '';
    for wp in wps {
        if wp.endswith('@@') {
            s += wp[0:-2];
        } else {
            s += wp + ' ';
        }
    }
    return s.split();
}