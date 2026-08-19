with entry {
    name: str = "Alice";
    age: int = 30;
    pi: float = 3.14159;
    active: bool = True;

    scores: list[int] = [90, 85, 88];
    average: float = sum(scores) / len(scores);
    print(f"{name} ({age}) avg={average}");
}
