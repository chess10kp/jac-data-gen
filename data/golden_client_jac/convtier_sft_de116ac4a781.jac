node City {
    has name: str;
    has population: int = 0;
}

walker SumPop {
    has total: int = 0;

    can tally with City entry {
        self.total += here.population;
        visit [-->];
    }
}

with entry {
    a = City(name="A", population=100);
    b = City(name="B", population=200);
    c = City(name="C", population=300);
    root ++> a;
    a ++> b;
    b ++> c;
    w = a spawn SumPop();
    print(w.total);
}
