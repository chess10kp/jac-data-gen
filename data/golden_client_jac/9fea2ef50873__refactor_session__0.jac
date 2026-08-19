walker Greeter {
    can start with Root entry;
    can greet with Person entry;
}

impl Greeter.start {
    visit [-->];
}

impl Greeter.greet {
    print(f"Hello, {here.name}!");
}
