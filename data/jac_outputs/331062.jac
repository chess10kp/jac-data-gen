"""Given a list of expected object names and upload results, verify all expected objects were uploaded."""
def _validate_manifest_upload(expected_objs: list[str], upload_results: list[dict[str, str | bool]]) -> bool {
    uploaded_objs = {
        r['object']
        for r in upload_results
        if r['success'] and r['action'] in ('upload_object', 'create_dir_marker')
    };
    return set(expected_objs).issubset(uploaded_objs);
}