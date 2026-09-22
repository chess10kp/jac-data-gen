"""Try and get the CCSDT(Q) energy"""
def anal_q(data_dict: dict[str, dict[str, float]]) -> float {
    try {
        q_dict = data_dict["ccsdtq"];
        q_energy = q_dict["ccsdt(q) energy"] - q_dict["ccsdt energy"];
    } except KeyError {
        q_energy = 0.0;
    }
    return q_energy;
}