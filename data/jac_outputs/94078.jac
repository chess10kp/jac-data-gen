""" Return the CPU loading for all the processors between last and ref measures.
    The average on all processors is inserted in front of the list. """
def cpu_statistics(last: list[list[int]], ref: list[list[int]]) -> list[float] {
    cpu = [];
    for unit in zip(last, ref) {
        work = unit[0][0] - unit[1][0];
        idle = unit[0][1] - unit[1][1];
        total = work + idle;
        cpu.append(100.0 * work / total if total else 0);
    }
    return cpu;
}