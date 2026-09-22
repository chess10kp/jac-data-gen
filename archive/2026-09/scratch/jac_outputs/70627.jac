"""Group URIs fixture."""
def group_uris(cesnet_groups: list[str]) -> dict[str, str] {
    return {
        'exists': 'urn:geant:cesnet.cz:groupAttributes:f0c14f62-b19c-447e-b044-c3098cebb426?=displayName=example#perun.cesnet.cz',
        'new': 'urn:geant:cesnet.cz:groupAttributes:f0c14f62-b19c-447e-b044-c3098c3bb426?=displayName=new#perun.cesnet.cz',
        'invalid': 'urn:geant:cesnet.cz:group:f0c14f62-b19c-447e-b044-c3098cebb426#perun.cesnet.cz'
    };
}