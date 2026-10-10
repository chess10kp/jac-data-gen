"""Contest logbook: one BandLog per Band on root; BandLog -Logged-> Qso."""

enum Band {
    B80M,
    B40M,
    B20M,
    B10M
}

node BandLog {
    has band: Band;
}

node Qso {
    has call: str;
    has minute: int;
    has zone: int;
}

edge Logged: BandLog --> Qso {}
