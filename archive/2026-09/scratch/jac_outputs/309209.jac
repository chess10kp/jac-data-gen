"""Input: a list of variable-bracketed strings, the known LCS
Output: number of variables needed and the variables themselves in a list."""
def _evalfact(lcs: str, c: list[str]) -> tuple[int, list[str]] {
    allbreaks = [];
    for w in c {
        breaks = [0] * len(lcs);
        p = 0;
        inside = 0;
        for pos in w {
            if pos == "[" {
                inside = 1;
            } elif pos == "]" {
                inside = 0;
                breaks[p - 1] = 1;
            } elif inside {
                p += 1;
            }
        }
        allbreaks.append(breaks);
    }
    finalbreaks = [0] * len(lcs);
    for br in allbreaks {
        for (idx, val) in enumerate(br) {
            if val == 1 {
                finalbreaks[idx] = 1;
            }
        }
    }
    variables = [];
    currvar = "";
    for (idx, val) in enumerate(lcs) {
        currvar += lcs[idx];
        if finalbreaks[idx] == 1 {
            variables.append(currvar);
            currvar = "";
        }
    }
    numvars = sum(finalbreaks);
    return (numvars, variables);
}