"""Return the header for the multi-homed section from an rsyslog conf file."""
def GetSyslogConfMultiHomedHeaderString(WorkspaceID: str) -> str {
    return '# OMS Syslog collection for workspace ' + WorkspaceID;
}