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
}
