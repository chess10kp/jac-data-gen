"""
    """
def get_cpu_frequency_cmd(cpu: Any) -> object {
    cmd = 'cat /sys/devices/system/cpu/{0}/cpufreq/scaling_cur_freq'.format(cpu);
    return cmd;
}