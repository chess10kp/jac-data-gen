"""
Replace the name of the encoding in the charset rule at the beginning of
``input`` with ``encoding``. If ``input`` doesn't starts with a charset
rule, ``input`` will be returned unmodified.

If the encoding can't be found yet, ``None`` is returned. ``final``
specifies whether more data will be available in later calls or not.
If ``final`` is true, ``_fixencoding()`` will never return ``None``.
"""
def _fixencoding(input: str, encoding: str, final: bool = False) -> str | None {
    prefix = '@charset "';
    if len(input) > len(prefix) {
        if input.startswith(prefix) {
            pos = input.find('"', len(prefix));
            if pos >= 0 {
                if encoding.replace("_", "-").lower() == "utf-8-sig" {
                    encoding = "utf-8";
                }
                return prefix + encoding + input[pos:];
            }
        } else {
            return input;
        }
    } elif not prefix.startswith(input) or final {
        return input;
    }
    if final {
        return input;
    }
    return None;
}