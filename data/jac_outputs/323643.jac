"""A function that returns the work done by a swimmer if they choose to escape from a rip current via strategy 1."""
def work_strategy1(l: float, Ve: float, Vr: float, Vf: float, wf: float, wr: float) -> float {
    W1 = ((Ve + Vr) ** 3) * ((l - wf) / Ve);
    W2 = ((Ve + Vf) ** 3) * (wf / Ve);
    if l - wf < 0 {
        return -1;
    }
    return W1 + W2;
}