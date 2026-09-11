"""Reference harness for iss_lightcloud00__herphase-pages__12."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_lightcloud00__herphase-pages__12.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_lightcloud00__herphase-pages__12.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

ROLE_CANONICAL = _mod.ROLE_CANONICAL
ROLE_MIRROR = _mod.ROLE_MIRROR
ROLE_LEGACY = _mod.ROLE_LEGACY
fresh_site_graph = _mod.fresh_site_graph
register_host = _mod.register_host
register_route = _mod.register_route
add_path_redirect = _mod.add_path_redirect
redirect_chain = _mod.redirect_chain
terminal_route = _mod.terminal_route
count_indexed_duplicates = _mod.count_indexed_duplicates
proves_canonical_terminus = _mod.proves_canonical_terminus

assert ROLE_CANONICAL == "canonical"
assert ROLE_MIRROR == "mirror"
assert ROLE_LEGACY == "legacy"

s0 = fresh_site_graph()
assert isinstance(s0, _mod.SiteGraph)
assert count_indexed_duplicates(s0) == 0

s1 = fresh_site_graph()
register_host("gds", ROLE_CANONICAL, False, s1)
register_host("github.io", ROLE_MIRROR, False, s1)
register_host("herphase.app", ROLE_LEGACY, True, s1)
register_route("gds", "/hub/", 200, s1)
register_route("github.io", "/hub/", 200, s1)
register_route("herphase.app", "/hub/", 200, s1)
add_path_redirect("herphase.app", "/hub/", "github.io", s1)
add_path_redirect("github.io", "/hub/", "gds", s1)
add_path_redirect("github.io", "/hub/", "herphase.app", s1)
chain = redirect_chain("herphase.app", "/hub/", s1)
assert chain == ["herphase.app::/hub/", "github.io::/hub/", "gds::/hub/"]
assert proves_canonical_terminus("herphase.app", "/hub/", s1)

s2 = fresh_site_graph()
register_host("gds", ROLE_CANONICAL, False, s2)
try:
    redirect_chain("ghost", "/", s2)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    terminal_route("gds", "/missing/", s2)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

s3 = fresh_site_graph()
register_host("gds", ROLE_CANONICAL, False, s3)
register_host("github.io", ROLE_MIRROR, False, s3)
register_host("herphase.app", ROLE_LEGACY, True, s3)
register_route("gds", "/support/", 200, s3)
register_route("github.io", "/support/", 200, s3)
register_route("herphase.app", "/support/", 200, s3)
add_path_redirect("herphase.app", "/support/", "github.io", s3)
add_path_redirect("github.io", "/support/", "gds", s3)
term = terminal_route("herphase.app", "/support/", s3)
assert term == {"host": "gds", "path": "/support/", "status": 200}
assert proves_canonical_terminus("herphase.app", "/support/", s3)

s4 = fresh_site_graph()
register_host("gds", ROLE_CANONICAL, False, s4)
register_host("herphase.app", ROLE_LEGACY, True, s4)
register_route("gds", "/privacy/", 200, s4)
register_route("herphase.app", "/privacy/", 404, s4)
term = terminal_route("herphase.app", "/privacy/", s4)
assert term == {"host": "herphase.app", "path": "/privacy/", "status": 404}
assert proves_canonical_terminus("herphase.app", "/privacy/", s4) is False

s5 = fresh_site_graph()
register_host("gds", ROLE_CANONICAL, False, s5)
register_host("github.io", ROLE_MIRROR, False, s5)
register_host("herphase.app", ROLE_LEGACY, True, s5)
assert count_indexed_duplicates(s5) == 1

try:
    register_host("gds", ROLE_CANONICAL, False, s5)
    raise AssertionError("expected ValueError")
except ValueError:
    pass
try:
    add_path_redirect("herphase.app", "/ghost/", "gds", s5)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("iss_lightcloud00__herphase-pages__12 ref OK")
print("iss_lightcloud00__herphase-pages__12 ref OK")
