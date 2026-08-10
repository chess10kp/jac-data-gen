"""Returns the c++ type associated with interfaces of the given name.

  Args:
    interface_name: the name of the interface you want the type for, or None.

  Returns:
    the c++ type which wayland will generate for this interface, or void* if
    the interface_name is none. We use "struct foo*" due to a collision between
    typenames and function names (specifically, wp_presentation has a feedback()
    method and there is also a wp_presentation_feedback interface).
  """
def GetCppPtrType(interface_name: str | None) -> str {
    if not interface_name {
        return 'void*';
    }
    return 'struct ' + interface_name + '*';
}