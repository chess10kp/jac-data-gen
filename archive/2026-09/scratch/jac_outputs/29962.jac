"""Return a human-readable text name corresponding to some Zernike term as specified
by `j`, the index

Only works up to term 22, i.e. 5th order spherical aberration.
"""
def zern_name(i: int) -> str {
    names = [
        'Null',
        'Piston',
        'Tilt X',
        'Tilt Y',
        'Focus',
        'Astigmatism 45',
        'Astigmatism 0',
        'Coma Y',
        'Coma X',
        'Trefoil Y',
        'Trefoil X',
        'Spherical',
        '2nd Astig 0',
        '2nd Astig 45',
        'Tetrafoil 0',
        'Tetrafoil 22.5',
        '2nd coma X',
        '2nd coma Y',
        '3rd Astig X',
        '3rd Astig Y',
        'Pentafoil X',
        'Pentafoil Y',
        '5th order spherical'
    ];
    if i < len(names) {
        return names[i];
    }
    return "Z%d" % i;
}