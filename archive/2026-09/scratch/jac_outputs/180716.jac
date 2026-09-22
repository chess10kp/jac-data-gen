"""Convert instantiation pair to assignments of internal variables."""
def to_internal_instsp(instsp: tuple[dict[str, str], dict[str, str]]) -> tuple[dict[str, str], dict[str, str]] {
    (tyinst, inst) = instsp;
    tyinst2 = {('_' + nm): T for (nm, T) in tyinst.items()};
    inst2 = {('_' + nm): t for (nm, t) in inst.items()};
    return (tyinst2, inst2);
}