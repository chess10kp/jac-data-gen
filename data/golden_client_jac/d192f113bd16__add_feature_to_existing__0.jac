node Person {
    has age: int,
        status: str;
}

node Employee {
    has salary: int,
        experience: int;
}

def example(people: list[Person], employees: list[Employee]) {
    # Filter people by age
    adults = people[?age >= 18];

    # Multiple conditions
    qualified = employees[?salary > 50000, experience >= 5];

    # On graph traversal results
    friends = [-->][?status == "active"];

    # Seniors: another range filter on the same list
    seniors = people[?age >= 65];

    # Highly-paid veterans as a chained filter over employees
    veterans = employees[?experience >= 10][?salary > 80000];
}
