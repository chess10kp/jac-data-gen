"""
as seen here: https://github.com/multinormal/ddsm/blob/master/ddsm-software/get_ddsm_groundtruth.m
original documentation: http://marathon.csee.usf.edu/Mammography/DDSM/case_description.html#OVERLAYFILE
rows and columns are swapped
"""
def path_to_directions(l: list[int]) -> list[list[int]] {
    chain_code = {
        0: [-1, 0],
        1: [-1, 1],
        2: [0, 1],
        3: [1, 1],
        4: [1, 0],
        5: [1, -1],
        6: [0, -1],
        7: [-1, -1]
    };
    return [chain_code[x] for x in l];
}