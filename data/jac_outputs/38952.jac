"""Renaming variables. This function simply translates variable names
    used in the code into Latex style variables usable in plots. These
    rules are valide for the double adder model

    Parameters
    ----------
    name : list of strings
        list of names to translate


    Returns
    -------
    name : list of strings
        translated list of names
    """
def renaming_modelGW(name: Any) -> object {
    name = [x.replace('tau_g', '$\\alpha$') if (`type(x) == str) else x for x in name];
    name = [
        x.replace('Lig2_fit', '$\\Lambda_f$') if (`type(x) == str) else x for x in name
    ];
    name = [
        x.replace('Lb_fit', '$\\Lambda_b$') if (`type(x) == str) else x for x in name
    ];
    name = [
        x.replace('Lig_fit', '$\\Lambda_i$') if (`type(x) == str) else x for x in name
    ];
    name = [
        x.replace('DeltaLgi', '$d\\Lambda_{if}$') if (`type(x) == str) else x
        for x in name
    ];
    name = [
        x.replace('DeltaLigb', '$d\\Lambda_{ib}$') if (`type(x) == str) else x
        for x in name
    ];
    name = [x.replace('Tbg', '$T_{ib}$') if (`type(x) == str) else x for x in name];
    name = [x.replace('Tg', '$T_{if}$') if (`type(x) == str) else x for x in name];
    name = [x.replace('rLig', '$R_{if}$') if (`type(x) == str) else x for x in name];
    return name;
}