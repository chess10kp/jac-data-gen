"""m_e= mass/charge; hv= accelerating voltage (V); mfield= magnet field (H)"""
def calculate_radius(m_e: float, hv: float, mfield: float) -> float {
    ((2 * m_e * hv) / (mfield ** 2)) ** 0.5
}