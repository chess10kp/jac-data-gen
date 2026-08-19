"""Functions in Jac."""

def factorial(n: int) -> int {
    if n == 0 { return 1; }
    else { return n * factorial(n-1); }
}

obj Person {
    has name: str;
    has age: int;

    def greet() -> None {
        print(f"Hello, my name is {self.name} and I'm {self.age} years old.");
    }
}

with entry {
    person = Person("John", 42);
    person.greet();
    print(f"5! = {factorial(5)}");
}
