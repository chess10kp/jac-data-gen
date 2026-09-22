"""
checks if the person is allowed to enter restaurant or not.
raises exception if age <= 0 and not int
raises exception if fully_vaxed is not a bool
"""
def restaurant_bouncer(age: int, fully_vaxed: bool = False) -> bool {
    assert isinstance(age, int), 'age must be an int';
    assert isinstance(fully_vaxed, bool), 'fully_vaxed must be a bool';
    assert age >= 0, 'age cannot be negative';
    if fully_vaxed or age < 18 {
        print('Allowed to enter restaurant');
        return True;
    }
    print('Sorry, not allowed in');
    return False;
}