"""Adds cls to decorator_state"""
def schema_decorator(decorators_state: dict[str, type], cls: type) -> type {
    decorators_state['schema'] = cls();
    return cls;
}