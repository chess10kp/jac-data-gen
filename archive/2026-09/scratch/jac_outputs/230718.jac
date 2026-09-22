"""Return app_id's subdomain as it would appear in a Mesos DNS A record."""
def marathon_app_id_to_mesos_dns_subdomain(app_id: str) -> str {
    '-'.join(reversed(app_id.strip('/').split('/')))
}