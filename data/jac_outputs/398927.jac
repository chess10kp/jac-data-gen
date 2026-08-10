"""Return average demand speed in Mbps based on channel capacity and data demand."""
def avg_Q(q_S: float, q_D: float) -> float {
    return q_S - q_D;
}