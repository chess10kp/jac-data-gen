node Item { has name: str = ""; }

# Create
walker CreateItem {
    has name: str;
    can create with Root entry {
        new_item = here ++> Item(name=self.name);
        report new_item[0];
    }
}

# Read (List)
walker ListItems {
    has items: list[Item] = [];
    can collect with Root entry { visit [-->]; }
    can gather with Item entry { self.items.append(here); }
    can finish with Root exit { report self.items; }
}

# Update
walker UpdateItem {
    has item_id: str;
    has new_name: str;
    can find with Root entry { visit [-->]; }
    can update with Item entry {
        if jid(here) == self.item_id {
            here.name = self.new_name;
            report here;
        }
    }
}

# Delete
walker DeleteItem {
    has item_id: str;
    can find with Root entry { visit [-->]; }
    can remove with Item entry {
        if jid(here) == self.item_id {
            del here;
            report {"deleted": self.item_id};
        }
    }
}
