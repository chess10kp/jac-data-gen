"""Recode doses in Level-4 data to 8 distinct dose classes."""
def recode_dose(dose_value: float) -> float {
    doses = [0.04, 0.12, 0.37, 1.11, 3.33, 10.0, 20.0, 25.0];
    for x in range(len(doses) - 1) {
        if (dose_value > 0.0) & (dose_value <= 0.04) {
            dose_value = 0.04;
        } elif doses[x] <= round(dose_value, 2) < doses[x + 1] {
            dose_value = doses[x];
        }
    }
    return dose_value;
}