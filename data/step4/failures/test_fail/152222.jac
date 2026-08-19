"""Return list of words that are anagrams."""
def anagrams(word: Any, words: Any) -> object {
    final_list = [];
    to_match = ''.join(sorted(word));
    for i in words {
        if (''.join(sorted(i)) == to_match) {
            final_list.append(i);
        }
    }
    return final_list;
}

test "t0" {
    assert (anagrams('a', []) == []);;
}

test "t1" {
    assert (anagrams('raiser', ['by', 'raising', 'raised']) == []);;
}

test "t2" {
    assert (anagrams('abba', ['aabb', 'abcd', 'bbaa', 'dada']) == ['aabb', 'bbaa']);;
}

test "t3" {
    assert (anagrams('iceman', ['cinemas']) == []);;
}

test "t4" {
    assert (anagrams('123', ['cba', 'abcd', '123', 'xyza', 'za', 'xyz']) == ['123']);;
}

test "t5" {
    assert (anagrams('abc', ['cba', 'abcd', '123', 'xyza', 'za']) == ['cba']);;
}

test "t6" {
    assert (anagrams('laser', ['lazing', 'lazy', 'lacer']) == []);;
}

test "t7" {
    assert (anagrams(anagrams.__doc__, []) == []);;
}

test "t8" {
    assert (anagrams('abba', ['aabb', 'abcd', 'bbaa', 'dada']) == ['aabb', 'bbaa']);;
}

test "t9" {
    assert (
        anagrams(
            'leading',
            ['gallery', 'ballerina', 'regally', 'clergy', 'largely', 'leading']
        )
        == ['leading']
    );;
}

test "t10" {
    assert (anagrams('iceman', []) == []);;
}

test "t11" {
    assert (
        anagrams("racer", ["crazer", "carer", "racar", "caers", "racer"])
        == ["carer", "racer"]
    );;
}

test "t12" {
    assert (anagrams('ab', ['ba', 'abc']) == ['ba']);;
}

test "t13" {
    assert (
        anagrams(
            'ballerina',
            ['gallery', 'ballerina', 'regally', 'clergy', 'largely', 'leading']
        )
        == ['ballerina']
    );;
}

test "t14" {
    assert (
        anagrams('racer', ['crazer', 'carer', 'racar', 'caers', 'racer'])
        == ['carer', 'racer']
    );;
}

test "t15" {
    assert (anagrams('ab', ['ba']) == ['ba']);;
}

test "t16" {
    assert (anagrams('laser', ['lazing', 'lazy', 'lacer']) == []);;
}

test "t17" {
    assert (anagrams('', []) == []);;
}

test "t18" {
    assert (
        anagrams(
            'clergy',
            ['gallery', 'ballerina', 'regally', 'clergy', 'largely', 'leading']
        )
        == ['clergy']
    );;
}

test "t19" {
    assert (
        anagrams('racer', ['crazer', 'carer', 'racar', 'caers', 'racer'])
        == ['carer', 'racer']
    );;
}

test "t20" {
    assert (anagrams("laser", ["lazing", "lazy", "lacer"]) == []);;
}

test "t21" {
    assert (anagrams("abba", ["aabb", "abcd", "bbaa", "dada"]) == ["aabb", "bbaa"]);;
}
