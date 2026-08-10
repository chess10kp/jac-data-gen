"""
Given a summary table of diploids, finds those
which are homozygous
"""
def findHomozygotes(diptable: dict[tuple[str, str], int] = {}) -> dict[tuple[str, str], int] {
    mydiptable = diptable;
    homozygouslist = [];
    for key in mydiptable.keys() {
        if key[0] == key[1] {
            homozygouslist.append(key);
        }
    }
    homozygtable = {};
    for key in homozygouslist {
        homozygtable[key] = mydiptable[key];
    }
    return homozygtable;
}