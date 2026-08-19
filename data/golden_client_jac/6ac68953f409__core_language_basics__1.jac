# Define the class (blueprint)
class Dog {
    has name: str = "Unnamed";
    has age: int = 0;

    def bark {
        print(f"{self.name} says Woof!");
    }
}

with entry {
    # Create objects (instances)
    my_dog = Dog();
    my_dog.name = "Buddy";
    my_dog.age = 3;

    your_dog = Dog();
    your_dog.name = "Max";
    your_dog.age = 5;

    # Use the objects
    my_dog.bark();   # Buddy says Woof!
    your_dog.bark(); # Max says Woof!

    print(f"{my_dog.name} is {my_dog.age} years old");
}
