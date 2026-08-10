"""Checks if a tag is in the set of SRL tags to include in the textpiece.

	:param tag (str): a pos tag from SRL output, e.g. 'B-V'.
	:param srl_args (list): a list of SRL tags to include in the textpiece set in the config, e.g. ['V', 'A1'].
	:return (bool): a boolean indicating if tag is in srl_args.
	"""
def overlap(tag: Any, srl_args: Any) -> object {
    flag = False;
    if (srl_args == 'all') {
        if (tag != 'O') {
            flag = True;
        }
    } else {
        tag = tag.split('-');
        for srl_arg in srl_args {
            if (srl_arg in tag) {
                flag = True;
                break;
            }
        }
    }
    return flag;
}