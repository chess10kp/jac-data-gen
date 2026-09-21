"""Follow citation trails through a wiki-style knowledge graph.

Articles connect to other articles with Cites edges and to authors
with WrittenBy edges. Starting from one article, the reader follows a
chain that switches edge types mid-walk: cited article first, then the
author behind it.
"""

node Article {
    has title: str;
}

node Author {
    has name: str;
}

edge Cites {}
edge WrittenBy: Article --> Author {}

walker Reader {
    can start with Root entry {
        visit [-->];
    }

    can read with Article entry {
        print(f"Reading article: {here.title}");

        # Hop 1 crosses a Cites edge, hop 2 crosses a WrittenBy edge --
        # mixed edge types chain naturally in one query
        sources_authors = [here ->:Cites:-> ->:WrittenBy:->];

        for a in sources_authors {
            print(f"  '{here.title}' cites work by author {a.name}");
        }

        # The reverse single hop also works from an article
        writers = [->:WrittenBy:->];
        if not writers {
            print("  (no author recorded)");
        } else {
            print(f"  written by {writers[0].name}");
        }
        visit [->:Cites:->];
    }

    can meet with Author entry {
        print(f"Met author {here.name} while reading");
    }
}

with entry {
    transformers = Article(title="Attention Is All You Need");
    bert = Article(title="BERT");
    vit = Article(title="Vision Transformer");
    ashish = Author(name="Ashish");
    jacob = Author(name="Jacob");

    transformers +>: Cites() :+> bert;
    transformers +>: Cites() :+> vit;
    bert +>: WrittenBy() :+> jacob;
    vit +>: WrittenBy() :+> ashish;

    root ++> transformers;
    root spawn Reader();
}
