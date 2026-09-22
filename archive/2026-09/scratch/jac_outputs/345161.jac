"""Check for 'assertRaises(Exception'.

nova HACKING guide recommends not using assertRaises(Exception...):
Do not use overly broad Exception type
N202
"""
def nova_except_format_assert(logical_line: str) -> tuple[int, str] | None {
    if logical_line.startswith("self.assertRaises(Exception") {
        return (1, "NOVA N202: assertRaises Exception too broad");
    }
}