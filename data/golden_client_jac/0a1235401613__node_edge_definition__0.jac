node A {
    has value: int = 0;
}
node B {
    has label: str = "";
}

with entry {
    a = A(value=1);
    b = B(label="hello");
    a ++> b;  # Connect a to b with default edge
}
