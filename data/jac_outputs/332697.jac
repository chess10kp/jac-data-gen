"""
Reverse the order of instances.

This function should be passed to :meth:`InstanceSet.select` without any
argument.
"""
def reverse[T](insts: list[T]) -> list[T] {
    return list(reversed(insts));
}