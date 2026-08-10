"""Returns a customized name of a rule. When the prefix matches a key
from 'prefix_dict', the prefix will be replaced with the
'prefix_dict[key]' value."""
def _llvm_get_rule_name(prefix_dict: dict[str, str], name: str) -> str {
    for (old_prefix, new_prefix) in prefix_dict.items() {
        if name.startswith(old_prefix) {
            return '%s%s' % (new_prefix, name[(len(old_prefix) + 1):]);
        }
    }
    return name;
}