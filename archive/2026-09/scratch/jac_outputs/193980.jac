"""
    Convert key value pairs from k1=v1,k2=v2 => {k1:v1,k2,v2} dict
    :param kv_pairs:
    :return:
    """
def parse_key_value_pairs(kv_pairs: str) -> object {
    return {
        kvs.split("=")[0]: kvs.split("=")[1]
        for kvs in kv_pairs.split(",")
        if (kvs.find("=") >= 0)
    };
}