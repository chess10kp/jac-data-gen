walker FindAdults {
    can start with Root entry;
    can check with Person entry;
}

impl FindAdults.start {
    visit [-->];
}

impl FindAdults.check {
    if here.age >= 18 {
        report here;
    }
    visit [-->];
}
