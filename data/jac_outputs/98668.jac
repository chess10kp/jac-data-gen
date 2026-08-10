"""
   Parameters:
   -----------
   m3: int
   dl: list of int
   Return:
   -------
   vol_m3: float
      volume in m3 from the dial and gauges values
      /!\ The nature of gauges means the gauge will show the next value early
      converting requires to take 1 away from digit if digit for smaller gauge is 9

       Example: reading gauges in order 2* 1/10 m3 + 9 *1/100 m3 = 0.19m3
   """
def meter_reading(m3: Any, dl: Any) -> object {
    dl = [str(x[0] if (x[1] < 9) else (x[0] - 1)) for x in zip(dl, (dl[1:] + [0]))];
    dl = int("".join(dl)) / (10 ** len(dl));
    return (m3 + dl);
}