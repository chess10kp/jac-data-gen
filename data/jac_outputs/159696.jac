"""Return the id part of the router-binding router-id field."""
def _get_obj_id_from_binding(router_id: str, prefix: str) -> str {
    return router_id[len(prefix):];
}