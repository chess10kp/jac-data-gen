"""
    this needs to returns an array of actions representing the depencies between actions.

    Looks at ACTION_DEPS in this module for an example of what is expected

    """
def init_actions_(service: str, args: list[str]) -> dict[str, list[str]] {
    return {
        'test_all': [
            'test_list_services',
            'test_delete_bp',
            'test_execute_bp',
            'test_get_bp',
            'test_restore_bp',
            'test_archive_bp',
            'test_update_bp',
            'test_create_bp',
            'test_list_bps',
            'test_delete_repo',
            'test_get_repo',
            'test_create_repo',
            'test_list_repos',
            'install'
        ]
    };
}