"""
    Purpose: Group the numerical list or 1D array by sequential blocks.
    Return: a list of list.
    """
def group_sequential(a: list[int]) -> list[list[int]] {
    if isinstance(a, int) {
        raise TypeError('Only list or 1D numpy array is accepted');
    } elif len(a) == 1 {
        return [[a[0]]];
    } else {
        ind_begin = 0;
        d = [];
        for i in range(len(a) - 1) {
            if a[i + 1] == a[i] + 1 {
                if i == len(a) - 2 {
                    d.append(list(a[ind_begin:len(a)]));
                }
            } else {
                ind_end = i;
                d.append(list(a[ind_begin:ind_end + 1]));
                ind_begin = i + 1;
                if i == len(a) - 2 {
                    d.append([a[i + 1]]);
                }
            }
        }
        return d;
    }
}