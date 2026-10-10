import from main { Bookmark, Tag, Tagged, clean_tags, SaveBookmark, FindByTag, TagCounts, DeleteBookmark }

test "save returns the bookmark" {
    b = (root spawn SaveBookmark(url="https://a.example", title="A", tags=["x"])).reports[0];
    assert b.url == "https://a.example";
}
