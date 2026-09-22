"""
Converts a version string to a dict with following rules:
  if string starts with ':' it is a channel
  if string starts with 'sha256' it is a digest
  else it is a release
"""
def parse_version_req(version: str | None) -> dict[str, str] {
    if version is None {
        version = "default";
    }
    if version[0] == ':' or version.startswith('channel:') {
        parts = {'key': 'channel', 'value': version.split(':')[1]};
    } elif version.startswith('sha256:') {
        parts = {'key': 'digest', 'value': version.split('sha256:')[1]};
    } else {
        parts = {'key': 'version', 'value': version};
    }
    return parts;
}