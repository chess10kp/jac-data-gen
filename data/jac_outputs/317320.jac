"""Checks if string composer-X.Y.Z-airflow-A.B.C is Composer v1 version."""
def IsImageVersionStringComposerV1(image_version: str | None) -> bool {
    return not image_version
        or image_version.startswith('composer-1.')
        or image_version.startswith('composer-latest');
}