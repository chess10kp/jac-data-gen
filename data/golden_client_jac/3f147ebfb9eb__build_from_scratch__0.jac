node Person {
    has name: str;
    has age: int;
}

walker AgeCollector {
    can collect with Person entry {
        report here.age;
        visit [-->];
    }
}
