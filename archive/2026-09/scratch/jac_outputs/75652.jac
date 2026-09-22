"""Return CondDB URL for given API name"""
def conddb_url(api: str = '') -> str {
    return 'http://cms-conddb.cern.ch/%s' % api;
}