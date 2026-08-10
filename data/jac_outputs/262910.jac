glob EPOCH_DAY1_MS = 31622400000.0;
glob MS_PER_DAY = 24.0 * 60.0 * 60.0 * 1000.0;

"""
Taken from spacepy https://pythonhosted.org/SpacePy/_modules/spacepy/pycdf.html#Library.epoch_to_num
Convert CDF EPOCH to matplotlib number.

Same output as :func:`~matplotlib.dates.date2num` and useful for
plotting large data sets without converting the times through datetime.
"""
def epoch_to_num(epoch: float) -> float {
    (epoch - EPOCH_DAY1_MS) / MS_PER_DAY + 1.0
}