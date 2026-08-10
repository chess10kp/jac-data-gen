def subnetToList(listoflist: list[str]) -> list[bytes] {
    d_temp = [];
    for l in listoflist {
        d_temp.append(l.encode('ascii'));
    }
    print(d_temp);
    return d_temp;
}