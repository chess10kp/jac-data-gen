"""Fix pool type string for display."""
def fix_pooltype(pooltype: str) -> str {
    if pooltype == 'Transactional' {
        pooltype = 'Transactional Workloads';
    } else {
        pooltype = '{0} Storage'.format(pooltype);
    }
    return pooltype;
}