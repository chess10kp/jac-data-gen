def trimVersionString(version_string):
    ### from munkilib.updatecheck
    """Trims all lone trailing zeros in the version string after major/minor.

    Examples:
      10.0.0.0 -> 10.0
      10.0.0.1 -> 10.0.0.1
      10.0.0-abc1 -> 10.0.0-abc1
      10.0.0-abc1.0 -> 10.0.0-abc1
    """
    if version_string == None or version_string == '':
        return ''
    version_parts = version_string.split('.')
    # strip off all trailing 0's in the version, while over 2 parts.
    while len(version_parts) > 2 and version_parts[-1] == '0':
        del(version_parts[-1])
    return '.'.join(version_parts)

assert trimVersionString('0') == '0'
assert trimVersionString('10.0.0.0.0.1') == '10.0.0.0.0.1'
assert trimVersionString('10.1.0') == '10.1'
assert trimVersionString('10.0.0') == '10.0'
assert trimVersionString('1.0.0.1') == '1.0.0.1'
assert trimVersionString('10.0.0-abc1.0.0') == '10.0.0-abc1'
assert trimVersionString('') == ''
assert trimVersionString('10.0.0.0.0.0') == '10.0'
assert trimVersionString('10.0.0.0-abc1.0') == '10.0.0.0-abc1'
assert trimVersionString('1.0.0.0') == '1.0'
assert trimVersionString('10.0') == '10.0'
assert trimVersionString('0.1') == '0.1'
assert trimVersionString(None) == ''
assert trimVersionString('10.0.0.0.0') == '10.0'
assert trimVersionString('10.1.0.0') == '10.1'
assert trimVersionString('10.1') == '10.1'
assert trimVersionString('1.0') == '1.0'
assert trimVersionString('10.0.0.0') == '10.0'
assert trimVersionString('10.0.1.0.0.1') == '10.0.1.0.0.1'
assert trimVersionString('10.0.0-abc1.0') == '10.0.0-abc1'
assert trimVersionString('10.0.0.1') == '10.0.0.1'
assert trimVersionString('10.0.0.0.1.0') == '10.0.0.0.1'
assert trimVersionString('0.0') == '0.0'
assert trimVersionString('1.0.1') == '1.0.1'
assert trimVersionString('10.0.0.1.0.0.0') == '10.0.0.1'
assert trimVersionString('10.0.0.0-abc1') == '10.0.0.0-abc1'
assert trimVersionString('1.0.0') == '1.0'
assert trimVersionString('10.0.0-abc1') == '10.0.0-abc1'
