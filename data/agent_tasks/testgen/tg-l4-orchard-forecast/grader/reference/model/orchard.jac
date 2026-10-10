"""Orchard layout: Block -HasRow-> Row -HasTree-> Tree."""
import from model.varieties { Variety }

node Block {
    has name: str;
}

node Row {
    has index: int;
}

node Tree {
    has tag: str;
    has variety: Variety;
    has age: int;
    has diseased: bool = False;
}

sem Tree.age = "Years since grafting.";

edge HasRow: Block --> Row {}

edge HasTree: Row --> Tree {}

"""Plant a block: rows is a list of rows, each a list of (tag, variety, age)."""
def plant_block(name: str, rows: list[list[tuple[str, Variety, int]]]) -> Block {
    blk = root ++> Block(name=name);
    for (i, trees) in enumerate(rows) {
        row = Row(index=i);
        blk +>:HasRow():+> row;
        for (tag, v, age) in trees {
            row +>:HasTree():+> Tree(tag=tag, variety=v, age=age);
        }
    }
    return blk;
}
