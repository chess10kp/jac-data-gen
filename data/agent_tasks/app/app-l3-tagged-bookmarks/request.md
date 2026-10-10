I'd like a terminal bookmark manager written in Jac, using the object-spatial graph properly: one `Bookmark` node per URL, one `Tag` node per tag name (shared between bookmarks — not a string list on the bookmark), and an edge from bookmark to tag. Everything lives under `root` and persists between runs. This directory already has the `jac create` CLI skeleton.

Walkers in `main.jac`:

- `SaveBookmark` (`url: str`, `title: str`, `tags: list[str]`) — saving a URL that already exists updates the title and adds any new tags (it never removes tags). Tags are lowercased and trimmed; blank tags ignored.
- `FindByTag` (`tag: str`) — reports one sorted list of URLs carrying that tag.
- `TagCounts` — reports one dict tag → number of bookmarks using it. Tags no bookmark uses anymore must not appear.
- `DeleteBookmark` (`url: str`) — removes the bookmark; reports `True` if it existed, `False` otherwise.

CLI (`jac run main.jac <command> ...`):

```
save <url> <title> <comma,separated,tags>
find <tag>          # one url per line, or "no bookmarks"
tags                # one "tag count" pair per line, sorted by tag
delete <url>        # "deleted" or "not found"
```
