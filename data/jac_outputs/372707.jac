"""Write BLAST query file from nested read counts."""
def queryMaker(readList: list[list[str]], outLoc: str = "queryTemp.txt") -> bool {
    f = open(outLoc, 'w');
    for (i, row) in enumerate(readList) {
        f.write('>' + str(i) + '\n');
        f.write(row[0] + '\n');
    }
    f.close();
    return True;
}