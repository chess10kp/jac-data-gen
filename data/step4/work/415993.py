def mergesort(unsorted_list):
    """Sort a list."""
    if len(unsorted_list) > 1:
        mid = len(unsorted_list) // 2
        left_half = unsorted_list[:mid]
        right_half = unsorted_list[mid:]

        mergesort(left_half)
        mergesort(right_half)

        i = 0
        j = 0
        k = 0

        while i < len(left_half) and j < len(right_half):
            if left_half[i] < right_half[j]:
                unsorted_list[k] = left_half[i]
                i = i + 1

            else:
                unsorted_list[k] = right_half[j]
                j = j + 1

            k = k + 1

        while i < len(left_half):
            unsorted_list[k] = left_half[i]
            i = i + 1
            k = k + 1

        while j < len(right_half):
            unsorted_list[k] = right_half[j]
            j = j + 1
            k = k + 1

        return unsorted_list

assert mergesort([1, 2, 3, 4, 5, 6]) == [1, 2, 3, 4, 5, 6]
assert mergesort(list('214356')) == ['1', '2', '3', '4', '5', '6']
assert mergesort(list('abc')) == list('abc')
assert mergesort(
    [1, 4, 10, 2, 3, 8, 0]) == [0, 1, 2, 3, 4, 8, 10]
assert mergesort(list("ba")) == list("ab")
assert mergesort(list(range(6))) == list(range(6))
assert mergesort(list([4, 1, 3, 2])) == list([1, 2, 3, 4])
assert mergesort([4, 1, 2, 3]) == [1, 2, 3, 4]
assert mergesort(list('abcde')) == ['a', 'b', 'c', 'd', 'e']
assert mergesort(['f', 't', 'c', 'a', 'g','s']) == ['a', 'c', 'f', 'g','s', 't']
assert mergesort(
    [1, 5, 8, 3, 4, 6, 9, 7, 2]
) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
assert mergesort([1, 1, 1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1, 1, 1]
assert mergesort(list('cba')) == ['a', 'b', 'c']
assert mergesort(
    [314, 5, -1, -6, 2, 415]
) == [-6, -1, 2, 5, 314, 415]
assert mergesort(list('abcd')) == ['a', 'b', 'c', 'd']
assert mergesort(list('fedcba')) == list('abcdef')
assert mergesort([5, 4, 3, 2, 1]) == [1, 2, 3, 4, 5]
assert mergesort(list('abcdab')) == ['a', 'a', 'b', 'b', 'c', 'd']
assert mergesort([1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1]
assert mergesort(list('baab')) == ['a', 'a', 'b', 'b']
assert mergesort(list(range(20))) == list(range(20))
assert mergesort([1, 2, 3, 4, 5, 6, 7, 8]) == [1, 2, 3, 4, 5, 6, 7, 8]
assert mergesort(list("abcde")) == list("abcde")
assert mergesort([1, 1, 1, 1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1, 1, 1, 1]
assert mergesort(list(range(4))) == [0, 1, 2, 3]
assert mergesort([1, 3, 2, 5, 6, 7, 0]) == [0, 1, 2, 3, 5, 6, 7]
assert mergesort([1, 3, 2]) == [1, 2, 3]
assert mergesort(list('213456')) == ['1', '2', '3', '4', '5', '6']
assert mergesort(list('1245367')) == ['1', '2', '3', '4', '5', '6', '7']
assert mergesort(list("gfedcba")) == list("abcdefg")
assert mergesort(list("ab")) == list("ab")
assert mergesort(list(reversed(range(100)))) == list(range(100))
assert mergesort(list([1, 2, 3, 4])) == list([1, 2, 3, 4])
assert mergesort([1, 2, 3, 4, 5]) == [1, 2, 3, 4, 5]
assert mergesort(list(range(12))) == list(range(12))
assert mergesort(list([2, 3, 1])) == list([1, 2, 3])
assert mergesort(list([1, 2, 3])) == list([1, 2, 3])
assert mergesort(list("cdab")) == list("abcd")
assert mergesort([1, 3, 5, 7, 9]) == [1, 3, 5, 7, 9]
assert mergesort([-10, -1, 0, 10, 100]) == [-10, -1, 0, 10, 100]
assert mergesort([1000, -5, 8, -3, 4, 6, -9, 7, 2]) == [-9, -5, -3, 2, 4, 6, 7, 8, 1000]
assert mergesort(list(range(5))) == [0, 1, 2, 3, 4]
assert mergesort([1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]) == [1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
assert mergesort([1, 2]) == [1, 2]
assert mergesort(list(range(200))) == list(range(200))
assert mergesort(list('4321')) == ['1', '2', '3', '4']
assert mergesort(list('abba')) == ['a', 'a', 'b', 'b']
assert mergesort(
    [3, 5, 1, 6, 2, 4]
) == [1, 2, 3, 4, 5, 6]
assert mergesort([1, 4, 5, 2, 3, 8]) == [1, 2, 3, 4, 5, 8]
assert mergesort(
    [5, 2, 1, 6, 4, 3, 7]) == [1, 2, 3, 4, 5, 6, 7], "Incorrect result for mergesort."
assert mergesort([1, 3, 2, 4]) == [1, 2, 3, 4]
assert mergesort([4, 3, 1, 2]) == [1, 2, 3, 4]
assert mergesort([1, 4, 3, 2]) == [1, 2, 3, 4]
assert mergesort([1, 2, 3]) == [1, 2, 3]
assert mergesort(list(range(7))) == list(range(7))
assert mergesort(list('235146')) == ['1', '2', '3', '4', '5', '6']
assert mergesort(list([1, 2, 4, 3])) == list([1, 2, 3, 4])
assert mergesort(list(range(19))) == list(range(19))
assert mergesort(list(range(15))) == list(range(15))
assert mergesort(list('edcba')) == ['a', 'b', 'c', 'd', 'e']
assert mergesort(list(range(2))) == [0, 1]
assert mergesort(list("dcba")) == list("abcd")
assert mergesort(list([2, 1, 3])) == list([1, 2, 3])
assert mergesort(list('231456')) == ['1', '2', '3', '4', '5', '6']
assert mergesort([2, 1, 3]) == [1, 2, 3]
assert mergesort(list(range(16))) == list(range(16))
assert mergesort([10, 9, 8, 7, 6, 5, 4, 3, 2, 1]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
assert mergesort(list('fedcba')) == ['a', 'b', 'c', 'd', 'e', 'f']
assert mergesort(list(range(1, 10))) == list(range(1, 10))
assert mergesort(list('cba')) == list('abc')
assert mergesort([3, 1]) == [1, 3]
assert mergesort([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
assert mergesort(
    [1, 4, 2, 6, 2, 5, 7, 9, 1, 3, 5, 7, 8, 9, 6]) == [1, 1, 2, 2, 3, 4, 5, 5, 6, 6, 7, 7, 8, 9, 9]
assert mergesort(list(reversed(range(20)))) == list(range(20))
assert mergesort(list("cba")) == list("abc")
assert mergesort([1, 3, 5, 7, 9, 2, 4, 6, 8, 10]) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
assert mergesort(list("edcba")) == list("abcde")
assert mergesort(list('abab')) == ['a', 'a', 'b', 'b']
assert mergesort(list([4, 1, 2, 3])) == list([1, 2, 3, 4])
assert mergesort([1, 5, 8, 3, 4, 6, 9, 7, 2]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
assert mergesort(list(range(9))) == list(range(9))
assert mergesort(list('cbaa')) == ['a', 'a', 'b', 'c']
assert mergesort(list([1, 3, 2])) == list([1, 2, 3])
assert mergesort([4, 2, 1, 3]) == [1, 2, 3, 4]
assert mergesort(list('aaa')) == ['a', 'a', 'a']
assert mergesort(list('zyxwvutsrqponmlkjihgfedcba')) == ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l','m', 'n', 'o', 'p', 'q', 'r','s', 't', '', 'v', 'w', 'x', 'y', 'z']
assert mergesort(list('hello')) == list('ehllo')
assert mergesort(list(range(3))) == [0, 1, 2]
assert mergesort(list(range(14))) == list(range(14))
assert mergesort(list('12345')) == ['1', '2', '3', '4', '5']
assert mergesort(list(range(18))) == list(range(18))
assert mergesort([2, 1, 3, 4]) == [1, 2, 3, 4]
assert mergesort(list('ab')) == list('ab')
assert mergesort(
    [314, 5, 1, 6, 2, 415]
) == [1, 2, 5, 6, 314, 415]
assert mergesort([1, 3, 4, 2]) == [1, 2, 3, 4]
assert mergesort(list(range(8))) == list(range(8))
assert mergesort(list('6541237')) == ['1', '2', '3', '4', '5', '6', '7']
assert mergesort([-5, -4, -3, -2, -1]) == [-5, -4, -3, -2, -1]
assert mergesort([1, 2, 3, 4, 5, 6, 7]) == [1, 2, 3, 4, 5, 6, 7]
assert mergesort(list(range(3))) == list(range(3))
assert mergesort(list([2, 1])) == list([1, 2])
assert mergesort(list(range(11))) == list(range(11))
assert mergesort(list("abc")) == list("abc")
assert mergesort([-2, -1, 0, 1, 2]) == [-2, -1, 0, 1, 2]
assert mergesort(list('7365142')) == ['1', '2', '3', '4', '5', '6', '7']
assert mergesort([1000, 5, 8, 3, 4, 6, 9, 7, 2]) == [2, 3, 4, 5, 6, 7, 8, 9, 1000]
assert mergesort([2, 3, 1]) == [1, 2, 3]
assert mergesort([3, 1, 2]) == [1, 2, 3]
assert mergesort([9, 7, 5, 3, 1]) == [1, 3, 5, 7, 9]
assert mergesort(list(range(100))[::-1]) == list(range(100))
assert mergesort([1, 2, 3, 4]) == [1, 2, 3, 4]
assert mergesort(list([3, 1, 2])) == list([1, 2, 3])
assert mergesort(list(range(5))) == list(range(5))
assert mergesort(list(range(10))) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
assert mergesort(list('bac')) == list('abc')
assert mergesort(
    [1, 3, 4, 1, 2, 5, 6]
) == [1, 1, 2, 3, 4, 5, 6]
assert mergesort([1, 4, 2, 3]) == [1, 2, 3, 4]
assert mergesort(['g','s', 'f', 't', 'c', 'a']) == ['a', 'c', 'f', 'g','s', 't']
assert mergesort(list('edcba')) == list('abcde')
assert mergesort([9, 8, 7, 6, 5, 4, 3, 2, 1, 0]) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
assert mergesort(
    [1, 3, 5, 7, 9, 2, 4, 6, 8, 0]) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
assert mergesort(list(range(17))) == list(range(17))
assert mergesort(list(range(13))) == list(range(13))
assert mergesort(list('abcdebc')) == ['a', 'b', 'b', 'c', 'c', 'd', 'e']
assert mergesort([1, 2, 4, 3]) == [1, 2, 3, 4]
assert mergesort(list(range(4))) == list(range(4))
assert mergesort([3, 2, 1]) == [1, 2, 3]
assert mergesort([1, 4, 5, 2, 7, 8, 3, 1]) == [1, 1, 2, 3, 4, 5, 7, 8]
assert mergesort(list("abcd")) == list("abcd")
assert mergesort([1, 1, 1, 1, 1, 1]) == [1, 1, 1, 1, 1, 1]
assert mergesort(list('abc')) == ['a', 'b', 'c']
assert mergesort(list([3, 2, 1])) == list([1, 2, 3])
assert mergesort(list('3671245')) == ['1', '2', '3', '4', '5', '6', '7']
assert mergesort(list('abcde')) == list('abcde')
assert mergesort(list('ab')) == ['a', 'b']
assert mergesort(list([1, 4, 2, 3])) == list([1, 2, 3, 4])
assert mergesort(list(range(100))) == list(range(100))
assert mergesort(list([1, 2])) == list([1, 2])
assert mergesort([2, 1]) == [1, 2]
assert mergesort([1, 2, 3, 4, 5, 6, 7, 8, 9]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
assert mergesort([3, 4, 1, 2]) == [1, 2, 3, 4]
assert mergesort(list("fedcba")) == list("abcdef")
assert mergesort(['t', 'c', 'a', 'g','s', 'f']) == ['a', 'c', 'f', 'g','s', 't']
assert mergesort([20, 18, 16, 14, 12, 10, 8, 6, 4, 2, 1]) == [1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
assert mergesort([4, 3, 2, 1, 1]) == [1, 1, 2, 3, 4]
assert mergesort(list(reversed(range(200)))) == list(range(200))
assert mergesort(['s', 'f', 't', 'c', 'a', 'g']) == ['a', 'c', 'f', 'g','s', 't']
assert mergesort(list('hello world')) == list(' dehllloorw')
assert mergesort(list(range(2))) == list(range(2))
assert mergesort(list(range(10))) == list(range(10))
assert mergesort([1, 2, 4, 7, 3, 9, 5, 6, 8]) == [1, 2, 3, 4, 5, 6, 7, 8, 9]
assert mergesort(
    [3, 2, 1]) == [1, 2, 3], "Incorrect result for mergesort."
assert mergesort(list('abcdefghijklmnopqrstuvwxyz')) == list('abcdefghijklmnopqrstuvwxyz')
assert mergesort([1, 2, 5, 4, 3]) == [1, 2, 3, 4, 5]
assert mergesort([3, 5, 2, 1, 8]) == [1, 2, 3, 5, 8]
assert mergesort(list('1652347')) == ['1', '2', '3', '4', '5', '6', '7']
