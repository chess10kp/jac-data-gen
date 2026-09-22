"""
Recursively apply keyFn and valueFn to keys and values in dicts and nested structures.
Returns the input unchanged when it is not a dict or non-empty list.
"""
def mutate_dict(
    inValue: dict | list | int | str | float | bool | None,
    keyFn: callable = lambda (k: str | int) { k; },
    valueFn: callable = lambda (v: str | int | float | bool | None) { v; },
    keyTypes: tuple[`type, ...] | None = None,
    valueTypes: tuple[`type, ...] | None = None,
    **kwargs: dict
) -> dict | list | int | str | float | bool | None {
    def recurse(value: dict | list | int | str | float | bool | None) -> dict | list | int | str | float | bool | None {
        return mutate_dict(
            value,
            keyFn=keyFn,
            valueFn=valueFn,
            keyTypes=keyTypes,
            valueTypes=valueTypes,
            **kwargs
        );
    }
    if isinstance(inValue, dict) {
        outputDict: dict = dict();
        for (k, v) in inValue.items() {
            if keyTypes is None or isinstance(keyTypes, tuple) and isinstance(k, keyTypes) {
                k = keyFn(k, **kwargs);
            }
            if valueTypes is None or isinstance(valueTypes, tuple) and isinstance(v, valueTypes) {
                v = valueFn(v);
            }
            if isinstance(v, dict) {
                outputDict[k] = recurse(v);
            } elif isinstance(v, list) {
                outputDict[k] = [recurse(i) for i in v];
            } else {
                outputDict[k] = v;
            }
        }
        return outputDict;
    } elif isinstance(inValue, list) and len(inValue) > 0 {
        return [recurse(i) for i in inValue];
    } else {
        return inValue;
    }
}