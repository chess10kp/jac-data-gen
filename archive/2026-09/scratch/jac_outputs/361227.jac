"""Celery configuration (defaults to eager tasks).

    Scope: module

    This fixture provides the default Celery configuration (eager tasks,
    in-memory result backend and exception propagation). It can easily be
    overwritten in a specific test module:

    .. code-block:: python

        # test_something.py
        import pytest

        pytest.fixture(scope='module')
        def celery_config(celery_config):
            celery_config['CELERY_ALWAYS_EAGER'] = False
            return celery_config
    """
def celery_config(celery_config: Any) -> object {
    celery_config.update(
        `dict(
            CELERY_ALWAYS_EAGER=True,
            CELERY_CACHE_BACKEND='memory',
            CELERY_EAGER_PROPAGATES_EXCEPTIONS=True,
            CELERY_RESULT_BACKEND='cache'
        )
    );
    return celery_config;
}