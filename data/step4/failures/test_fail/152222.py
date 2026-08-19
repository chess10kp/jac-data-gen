def anagrams(word, words):
    """Return list of words that are anagrams."""
    final_list = []
    to_match = ''.join(sorted(word))
    for i in words:
        if ''.join(sorted(i)) == to_match:
            final_list.append(i)
    return final_list

assert anagrams('a', []) == []
assert anagrams('raiser', ['by', 'raising', 'raised']) == []
assert anagrams(
    'abba', ['aabb', 'abcd', 'bbaa', 'dada']) == ['aabb', 'bbaa']
assert anagrams(
    'iceman', ['cinemas']) == []
assert anagrams('123', ['cba', 'abcd', '123', 'xyza', 'za', 'xyz']) == ['123']
assert anagrams('abc', ['cba', 'abcd', '123', 'xyza', 'za']) == ['cba']
assert anagrams('laser', ['lazing', 'lazy',  'lacer']) == []
assert anagrams(anagrams.__doc__, []) == []
assert anagrams(
    'abba',
    ['aabb', 'abcd', 'bbaa', 'dada']) == ['aabb', 'bbaa']
assert anagrams('leading', ['gallery', 'ballerina','regally', 'clergy', 'largely', 'leading']) == ['leading']
assert anagrams(
    'iceman', []) == []
assert anagrams(
    "racer",
    ["crazer", "carer", "racar", "caers", "racer"]) == ["carer", "racer"]
assert anagrams('ab', ['ba', 'abc']) == ['ba']
assert anagrams('ballerina', ['gallery', 'ballerina','regally', 'clergy', 'largely', 'leading']) == ['ballerina']
assert anagrams(
    'racer',
    ['crazer', 'carer', 'racar', 'caers', 'racer']) == ['carer', 'racer']
assert anagrams('ab', ['ba']) == ['ba']
assert anagrams(
    'laser',
    ['lazing', 'lazy',  'lacer']) == []
assert anagrams('', []) == []
assert anagrams('clergy', ['gallery', 'ballerina','regally', 'clergy', 'largely', 'leading']) == ['clergy']
assert anagrams(
    'racer', ['crazer', 'carer', 'racar', 'caers', 'racer']) == ['carer', 'racer']
assert anagrams(
    "laser",
    ["lazing", "lazy",  "lacer"]) == []
assert anagrams(
    "abba",
    ["aabb", "abcd", "bbaa", "dada"]) == ["aabb", "bbaa"]
