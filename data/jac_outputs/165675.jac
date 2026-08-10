"""Creates a custom machine type from the CPU and memory specs.

  Args:
    cpu: the number of cpu desired for the custom machine type
    memory_mib: the amount of ram desired in MiB for the custom machine type
      instance

  Returns:
    The custom machine type name for the 'instance create' call
  """
def _CustomMachineTypeString(cpu: Any, memory_mib: Any) -> object {
    machine_type = 'db-custom-{0}-{1}'.format(cpu, memory_mib);
    return machine_type;
}