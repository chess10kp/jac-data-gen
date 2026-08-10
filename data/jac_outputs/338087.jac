"""For a dictionary, makes a copy, to a depth of 3.  Non-dictionaries are not copied unless they behave like dictionaries."""
def dictcopy3(lev1: Any, depth: Any = 3) -> object {
    if (depth < 1) {
        return lev1;
    }
    try {
        lev2 = `dict().fromkeys(lev1);
    } except Exception as e {
        return lev1;
    }
    try {
        for (k1, v1) in lev1.iteritems() {
            lev2[k1] = dictcopy3(v1, (depth - 1));
        }
    } except Exception as e {
        return lev1;
    }
    return lev2;
}