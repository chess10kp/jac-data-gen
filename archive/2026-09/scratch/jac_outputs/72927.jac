"""Tests for registers to verify that our glitch worked."""
def conditions(ctx: dict[str, dict[str, int]]) -> bool {
    return ctx['regs']['rax'] == 0;
}