"""parameter s: a string
parameter c: what we're counting
parameter maxRun: maximum length of run
returns: the number of times that string occurs in a row
This is the first step in the run sequence"""
def countRun(s: str, c: str, maxRun: int, count: int) -> int {
    """
    trial:
    def countRunHelp(s,c,maxRun, count):
        if count == maxRun:
            return c
        if s[count] == s[count+1]:
            c+=1
        return countRunHelp(s, c, maxRun, count+1)
    return countRunHelp(s, c, maxRun, 0)
    """;
    if s == '' {
        return 0;
    }
    if count >= maxRun {
        return 0;
    }
    if s[:len(c)] != c {
        return 0;
    }
    1 + countRun(s[len(c):], c, maxRun, count + 1)
}