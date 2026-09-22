"""Assemble param for get_second_validate."""
def get_second_validate_param(tel_num: str) -> dict[str, str] {
    param_dict = dict();
    param_dict['act'] = '1';
    param_dict['source'] = 'wsyytpop';
    param_dict['telno'] = tel_num;
    param_dict['password'] = '';
    param_dict['validcode'] = '';
    param_dict['authLevel'] = '';
    param_dict['decode'] = '1';
    param_dict['iscb'] = '1';
    return param_dict;
}