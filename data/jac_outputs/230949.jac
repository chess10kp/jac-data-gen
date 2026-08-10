glob OUT_DIRECT_DEFAULTS = {
    "console": "1",
    "monitor": "2",
    "trapbuffer": "3",
    "logbuffer": "4",
    "snmp": "5",
    "logfile": "6"
};

"""get default out direct"""
def get_out_direct_default(out_direct: str) -> str | None {
    return OUT_DIRECT_DEFAULTS.get(out_direct);
}