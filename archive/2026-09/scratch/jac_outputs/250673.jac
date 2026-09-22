"""convert bytes to megabytes, etc.
       sample code:
           print('mb= ' + str(bytesto(314575262000000, 'm')))
       sample output:
           mb= 300002347.946
    """
def bytesto(bytes: int | float, to: str, bsize: int = 1024) -> float {
    a = {'k': 1, 'm': 2, 'g': 3, 't': 4, 'p': 5, 'e': 6};
    r = float(bytes);
    for i in range(a[to]) {
        r = r / bsize;
    }
    return r;
}