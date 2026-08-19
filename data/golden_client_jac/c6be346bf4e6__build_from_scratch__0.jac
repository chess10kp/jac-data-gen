def _cur(sh: any) -> list {
    return sh.proj if sh.mode == 0x1701 else sh.mv;
}
