walker FindFirst {
    can start with Root entry;
    can check with Person entry;
}

impl FindFirst.start {
    visit [-->];
}

impl FindFirst.check {
    if here.age >= 18 {
        report here;
        disengage;
    }
    visit [-->];
}
