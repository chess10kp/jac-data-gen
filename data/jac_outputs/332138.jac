"""
a int list such as [0,1,2,3] -> the denominator 7 of 0+1/(1+1/(2+1/3)))=10/7
even though the func returns the variable int_numerator
"""
def func_from_fraction_continued(list_int_generator: list[int]) -> int {
    int_denominator = 1;
    int_numerator = 0;
    while len(list_int_generator) != 0 {
        int_denominator_new = list_int_generator.pop() * int_denominator + int_numerator;
        int_numerator = int_denominator;
        int_denominator = int_denominator_new;
    }
    return int_numerator;
}