"""
Returns a dictionary based on an original dictionary
where previous keys are values and previous values pass
to be the keys
"""
def reverse_dict(original: dict) -> dict {
    final = {};
    for (k, value) in original.items() {
        if (type(value) == list) {
            for v in value as list[str] {
                final.setdefault(v, []).append(k);
            }
        } else {
            final.setdefault(value, []).append(k);
        }
    }
    return final;
}