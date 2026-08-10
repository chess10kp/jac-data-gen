"""Extra parameter for parameterized gate in HiQASM cmd."""
def _extr_parameter(cmd: Any) -> object {
    return [float(i) for i in cmd.split(' ')[-1].split(',')];
}