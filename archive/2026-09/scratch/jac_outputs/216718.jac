"""
	Convert integer i to a list of {0,1} of length n
	"""
def _int_to_bin(i: int, n: int) -> list[int] {
    [int(x) for x in list('{0:0{1}b}'.format(i, n))]
}