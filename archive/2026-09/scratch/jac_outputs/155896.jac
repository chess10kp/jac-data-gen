"""Add set of labels to an axonset or create new axonset."""
def classify_label_list(MAlist: list[set[str]], labelset: set[str]) -> list[set[str]] {
    found = False;
    for (i, MA) in enumerate(MAlist) {
        for l in labelset {
            if l in MA {
                MAlist[i] = MA | labelset;
                found = True;
                break;
            }
        }
    }
    if not found {
        MAlist.append(labelset);
    }
    return MAlist;
}