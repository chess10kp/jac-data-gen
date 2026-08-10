"""Get pvid, pvid_adapter, and virt_adapters from the configured SEA device.
Also get the state of the SEA."""
def get_sea_attribute_cmd(seaname: str) -> str {
    return "ioscli lsdev -dev %(sea)s -attr pvid,pvid_adapter,virt_adapters;"
        "ioscli lsdev -type sea | grep %(sea)s" % {'sea': seaname};
}