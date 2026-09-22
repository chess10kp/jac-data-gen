"""convert string to bool (used to pass arguments with argparse)"""
def str2bool(val: str) -> bool {
    dict = {
        'True': True,
        'False': False,
        'true': True,
        'false': False,
        '1': True,
        '0': False
    };
    return dict[val];
}