"""For making the ``ArgumentParser`` understand boolean values"""
def str2bool(v: str) -> bool {
    return v.lower() in ("yes", "true", "t", "1");
}