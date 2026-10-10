# cvt-l4-bookstore-catalog
Source danylevych/ksd-bookstore-parser (MIT) @86e3f7d. FARM L4 upsert semantics: the Mongo
`author_id` reference becomes an Author -[Wrote]-> Book edge; refresh-by-url must re-link the edge
when the author changes. Optional `count_in_complect=None` treated as 1 (upstream would crash).
Negatives: author not reused, url not upserted (duplicates), author change ignored, complect saved,
fields not refreshed.
