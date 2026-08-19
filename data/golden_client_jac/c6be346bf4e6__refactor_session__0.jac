obj Shim {
    has proj: list = [], mv: list = [], mode: int = 0x1700;
    def cur() -> list;
}

impl Shim.cur {
    return self.proj if self.mode == 0x1701 else self.mv;
}

with entry {
    a = Shim(proj=[1.0, 2.0], mv=[3.0, 4.0], mode=0x1701);
    b = Shim(proj=[1.0, 2.0], mv=[3.0, 4.0], mode=0x1700);
    print(str(_cur(a)));
    print(str(_cur(b)));
}
