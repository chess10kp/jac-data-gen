"""Substitution for unary multioperations."""
def unary_superposition_mop_r_3(ar_1: tuple[int, int, int], mop: tuple[int, ...]) -> tuple[int, int, int] {
    dic_mop = {
        1: (0,),
        2: (1,),
        3: (0, 1),
        4: (2,),
        5: (0, 2),
        6: (1, 2),
        7: (0, 1, 2)
    };
    a = 0;
    b = 0;
    c = 0;
    if ar_1[0] != 0 {
        for x in dic_mop[ar_1[0]] {
            a = a | mop[x];
        }
    }
    if ar_1[1] != 0 {
        for x in dic_mop[ar_1[1]] {
            b = b | mop[x];
        }
    }
    if ar_1[2] != 0 {
        for x in dic_mop[ar_1[2]] {
            c = c | mop[x];
        }
    }
    return (a, b, c);
}