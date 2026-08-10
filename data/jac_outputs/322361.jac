"""
Permissions for dhcp-related options
DHCP options are global like SOAs, related to subnets and ranges
"""
def has_dhcp_option_perm(user_level: str, `obj: str, ctnr: str, action: str) -> bool {
    return {
        'cyder_admin': True,
        'ctnr_admin': True,
        'user': True,
        'guest': action == 'view'
    }.get(user_level, False);
}