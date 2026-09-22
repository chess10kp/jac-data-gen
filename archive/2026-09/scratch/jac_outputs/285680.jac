"""
  Suma los digitos de un numero de 2 cifras
  """
def sum_digits(num: int) -> int {
    ult_dig = num % 10;
    pri_dig = num // 10;
    return pri_dig + ult_dig;
}