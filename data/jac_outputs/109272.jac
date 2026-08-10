"""
    Calculate approximate age at death for employees
    Assumes that they have a birth year and death year filled
    """
obj Employee {
    def age_at_death() -> int;
}

def get_ages_at_death(employees: list[Employee]) -> list[int] {
    return [emp.age_at_death() for emp in employees];
}