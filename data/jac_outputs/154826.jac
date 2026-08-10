"""
        Print consistent string format of seconds passed.
        Example: 300 = '5 mins'
        Example: 86400 = '1 day'
        Example: 86705 = '1 day, 5 mins, 5 sec'
    """
def timedur(x: Any) -> object {
    divs = [('days', 86400), ('hours', 3600), ('mins', 60)];
    x = float(x);
    res = [];
    for (lbl, sec) in divs {
        if (x >= sec) {
            (rm, x) = divmod(x, float(sec));
            if (rm == 1.0) {
                res.append((lbl[:-1], int(rm)));
            } else {
                res.append((lbl, int(rm)));
            }
        }
    }
    x = int(x);
    if (x == 1) {
        res.append(("second", x));
    } elif (x == 0) {
        ;
    } else {
        res.append(("seconds", x));
    }
    return ", ".join([("%d %s" % (w[1], w[0])) for w in res]);
}