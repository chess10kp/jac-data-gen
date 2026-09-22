"""Sing a verse"""
def verse(bottle: int) -> str {
    bottle_str = str(bottle);
    s1 = 's' if bottle > 1 else '';
    s2 = 's' if bottle != 2 else '';
    next_bottle = str(bottle - 1) if bottle > 1 else 'No more';
    return '\n'.join([
        f'{bottle_str} bottle{s1} of beer on the wall,',
        f'{bottle_str} bottle{s1} of beer,',
        'Take one down, pass it around,',
        f'{next_bottle} bottle{s2} of beer on the wall!'
    ]);
}