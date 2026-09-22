"""
Create a method named "rotate" that returns a given array with the elements
inside the array rotated n spaces.
with array [1, 2, 3, 4, 5]
n = 7        =>    [4, 5, 1, 2, 3]
n = 11       =>    [5, 1, 2, 3, 4]
n = -3       =>    [4, 5, 1, 2, 3]
"""
def rotate(data: list[int], n: int) -> list[int] {
    if data {
        k = len(data);
        n = n % k;
        return data[(k - n):] + data[:(k - n)];
    }
    return data;
}