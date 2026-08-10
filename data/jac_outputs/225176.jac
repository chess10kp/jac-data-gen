glob POZYX_FUNC_LO_1 = 0xB0;
glob POZYX_FUNC_HI_1 = 0xBC;
glob POZYX_FUNC_LO_2 = 0xC0;
glob POZYX_FUNC_HI_EXCL_2 = 0xC9;

"""Returns whether a Pozyx register is a Pozyx function."""
def is_functioncall(reg: int) -> bool {
    return (POZYX_FUNC_LO_1 <= reg <= POZYX_FUNC_HI_1) or (POZYX_FUNC_LO_2 <= reg < POZYX_FUNC_HI_EXCL_2);
}