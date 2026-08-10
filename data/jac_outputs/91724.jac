"""Get the IP address of a host from the /etc/hosts file."""
def get_address_from_hosts_file(hostname: str) -> str {
    hosts = open('/etc/hosts');
    for line in hosts {
        if line.strip() and line.split()[1] == hostname {
            return line.split()[0];
        }
    }
    raise Exception("Hostname %s not found in /etc/hosts" % hostname);
}