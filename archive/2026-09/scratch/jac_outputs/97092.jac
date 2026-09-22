"""Reweights corrected jet pt from minbias to mock up triggered spectrum."""
def minbias_jet_weight_true(x: float) -> float {
    1.149 - 0.2655 * x + 0.01857 * (x ** 2) - 0.0003445 * (x ** 3)
}