def eqiv(values):
    """Recursive function that does eqivalent boolean operations
    Example:
        Input: [True, True, False, False]
        (((True == True) == False) == False)) is True
    """
    try:
        values = list(values)
    except TypeError:
        return values
    try:
        outcome = values[0] == values[1]
    except IndexError:
        return values[0]
    try:
        new_values = [outcome] + values[2:]
        return eqiv(new_values)
    except IndexError:
        return outcome

assert eqiv(0j) == 0j
assert eqiv([True, True, True, True, True, True, False]) == False
assert eqiv([False]) == False
assert eqiv(1) == 1
assert eqiv([False, True, False, False]) == False
assert eqiv([False, False, False, False, False, False, False, True]) == False
assert eqiv([False, False, True, True]) == True
assert eqiv(0) == 0
assert eqiv([0, 0, 0]) == 0
assert eqiv([1]) == 1
assert eqiv([False, False, False, True, True]) == False
assert eqiv([0, True]) == 0
assert eqiv([[[True, True], [True, False]], [[False, True], [False, True]]]) == False
assert eqiv([True, True, True, False]) == False
assert eqiv([True, False, False, False]) == False
assert eqiv([True, True, False]) == False
assert eqiv([True, True, False, True]) == False
assert eqiv([1, 2, 3, 4]) == False
assert eqiv([True, False, False, True, False, True, False, False, True]) == False
assert eqiv([True, True, True, True, True]) == True
assert eqiv([False, True, False, False, True]) == False
assert eqiv(False) == False
assert eqiv([1, 0]) == False
assert eqiv([True, False, True, False, True, False, True, False]) == True
assert eqiv([True, True, True, True, True, True, True]) == True
assert eqiv([1, 1, 2, 3, 4]) == False
assert eqiv([True, False, False, False, True]) == False
assert eqiv([True, [True, True], True, True, [True, False]]) == False
assert eqiv([True, True, True, True]) == True
assert eqiv(0.123456789) == 0.123456789
assert eqiv([5]) == 5
assert eqiv([True, True, True]) == True
assert eqiv([False, [False, True], [False, True]]) == False
assert eqiv([1, 1, 1, 1]) == True
assert eqiv(5) == 5
assert eqiv([1, 2, 3, 3]) == False
assert eqiv([1, 1, 1, 2]) == False
assert eqiv([[[True, False], [True, False]], [[True, False], [True, False]]]) == True
assert eqiv([True, True, True, True, False, True]) == False
assert eqiv([False, False, True, False, True]) == False
assert eqiv([False, False, False, False, False]) == False
assert eqiv([True, True, True, True, True, True]) == True
assert eqiv(10) == 10
assert eqiv(123456789) == 123456789
assert eqiv([1, 0]) == 0
assert eqiv([True, [False, True], True, True]) == False
assert eqiv([True, False, True, False, False, False, False]) == False
assert eqiv([0]) == 0
assert eqiv([False, True, True, True]) == False
assert eqiv([True, False, True, False, True, False, True, True]) == False
assert eqiv([[True, False], [False, True]]) == False
assert eqiv(2) == 2
assert eqiv([1, 1, 2, 3]) == False
assert eqiv([True, [True, True], True, True, [False, True]]) == False
assert eqiv(0.0) == 0.0
assert eqiv([False, True]) == False
assert eqiv([1, True]) == 1
assert eqiv([False, True, True]) == False
assert eqiv(type(None)) == type(None)
assert eqiv([0, 0, 0, 0]) == True
assert eqiv([True, True, True, True, False]) == False
assert eqiv([[True, False], False]) == False
assert eqiv([False, False, False]) == False
assert eqiv([True, False, True]) == False
assert eqiv([True, [True, False], True, True]) == False
assert eqiv([0, 1]) == 0
assert eqiv([True, True, False, True, True]) == False
assert eqiv(None) == None
assert eqiv([True, True, False, False, False]) == False
assert eqiv(True) == True
assert eqiv([True, True, False, False, False, True, False]) == True
assert eqiv([False, False]) == True
assert eqiv([[[True, False], [True, False]], [[False, True], [False, True]]]) == False
assert eqiv([True, True, False, False]) == True
assert eqiv([True, False, False, True, False, False, False]) == False
assert eqiv([False, False, False, False]) == True
assert eqiv([True, False, True, False, False]) == False
assert eqiv([True, True, False, False, True, True, False]) == False
assert eqiv([True, False, False, True, False, False, True]) == True
assert eqiv([True, True]) == True
assert eqiv([[True, False], [True, False]]) == True
assert eqiv([True, False, False, True]) == True
assert eqiv([1, 1]) == 1
assert eqiv([False, False, False, True]) == False
assert eqiv([True, True, False, True, False, True, False, False, True]) == True
assert eqiv([True, True, True, True, False, True, True]) == False
assert eqiv([True, False]) == False
assert eqiv([True, False, True, True]) == False
assert eqiv([True]) == True
assert eqiv([True, True, True, False, True]) == False
assert eqiv([False, False, True, False]) == False
assert eqiv([False, False, False, False, False, False, False, False, False]) == False
