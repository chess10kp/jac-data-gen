import from six.moves.urllib.parse { urljoin as sys_urljoin }
import from functools { reduce }

"""Construct an absolute URL from several URL components."""
def urljoin(*args: str) -> str {
    reduce(sys_urljoin, args)
}