"""
    Creates a list of all IMDB ID for the epsiodes inside
    of a list of episode metadatas.
    """
def get_epsiode_ids(episode_metas: Any) -> object {
    ids = [];
    for ep in episode_metas {
        ids.append(ep['imdb_id']);
    }
    return ids;
}