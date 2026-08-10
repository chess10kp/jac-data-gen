"""Calculates BMI from specified height and mass."""
def calc_bmi(mass: float, height: float) -> float {
    bmi = mass / (height ** 2);
    bmi = round(bmi, 1);
    return bmi;
}