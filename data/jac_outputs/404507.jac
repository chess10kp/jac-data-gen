"""
    Helper function for to determine periodicity of a crystal, used in
    various functions

    inputs
    --------
        scale (float):      The ratio of final and initial network size
        supercell (int):    The supercell size used to generate the new
                            atomic network


    returns
    --------
        motiif (str):   The structural motiif of the crystal

    """
def getDim(scale: Any, supercell: Any) -> object {
    motiif_dict = {
        1: 'molecular',
        supercell: 'chains',
        (supercell ** 2): 'layered',
        (supercell ** 3): 'conventional'
    };
    if (scale in motiif_dict) {
        return motiif_dict[scale];
    } else {
        if (scale < 1) {
            motiif = 'shrunk molecular';
        } elif (scale < supercell) {
            motiif = "mol-chain";
        } elif (scale < (supercell ** 2)) {
            motiif = "chain-2D";
        } elif (scale < (supercell ** 3)) {
            motiif = "2D-conv";
        } else {
            motiif = 'Network size increased';
        }
        return motiif;
    }
}