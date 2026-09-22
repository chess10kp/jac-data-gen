""" get the ratio of GC pairs to the total number of  pairs from a  DNA strings """
def get_frequency_GC_str(string: Any) -> object {
    GC = [];
    total = len(string);
    for i in string {
        if ((i == 'C') or (i == 'G')) {
            GC.append(1);
        }
    }
    return float((sum(GC) / total));
}