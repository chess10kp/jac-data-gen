"""
Add up all the temperature and count average.

:param ave: Integer, The average of all temperature before last input
:param number: Integer, number>0. The total amount of temperature
:param new: Integer, new!=EXIT, The lasted temperature input
:return: ave: Integer, The current average temperature
"""
def average_t(ave: int, number: int, new: int) -> float {
    return (ave * (number - 1) + new) / number;
}