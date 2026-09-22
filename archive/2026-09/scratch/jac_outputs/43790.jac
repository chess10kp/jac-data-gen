"""
    Eq. 4 of [IRB]_, which provides an estimate of the error of the interleaved gate,
    given both the observed interleaved and standard decay parameters.

    :param irb_decay: Observed decay parameter in irb experiment with desired gate interleaved
    between Cliffords
    :param rb_decay: Observed decay parameter in standard rb experiment.
    :param dim: Dimension of the Hilbert space, 2**num_qubits
    :return: Estimated gate error of the interleaved gate.
    """
def irb_decay_to_gate_error(irb_decay: float, rb_decay: float, dim: int) -> float {
    (dim - 1) / dim * (1 - irb_decay / rb_decay)
}