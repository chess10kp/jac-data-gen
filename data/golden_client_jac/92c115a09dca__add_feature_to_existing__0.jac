can collect with Item entry {
    if here.value % 2 == 0 {
        report here.value;
        self.total += here.value;
    }
    visit [-->];
}
