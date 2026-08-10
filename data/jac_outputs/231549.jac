"""Convert a scoped name string into the corresponding skeleton
module name. e.g. M1.M2.I -> M1__POA.M2.I"""
def skeletonModuleName(mname: str) -> str {
    parts = mname.split(".");
    parts[0] = parts[0] + "__POA";
    return ".".join(parts);
}