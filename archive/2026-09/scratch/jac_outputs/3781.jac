"""Returns arm_version for the GN build with the given architecture."""
def _GetArmVersion(arch: str) -> int | None {
    match arch {
        case 'armeabi':
            return 6;
        case 'armeabi-v7a':
            return 7;
        case x if x in ('arm64-v8a', 'x86', 'x86_64'):
            return None;
        case _:
            raise Exception('Unknown arch: ' + arch);
    }
}