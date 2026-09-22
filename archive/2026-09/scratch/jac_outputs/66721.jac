glob BMI_FACTOR = 703;

"""Returns the BMI of a client with the given values.
Formula used is: BMI = (weight * 703) / height ^2"""
def bmi(height: float, weight: float) -> float {
    return round((weight * BMI_FACTOR) / (height ** 2), 1);
}