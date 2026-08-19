node Product { has name: str = ""; has price: float = 0.0; }
node Book(Product) { has title: str = ""; has author: str = ""; }
node Magazine(Product) { has title: str = ""; has issue: int = 0; }
node Electronics(Product) { has warranty_years: int = 0; }

walker ShoppingCart {
    has total: float = 0.0;

    can process_item with Product entry {
        print(f"Processing {type(here).__name__}...");
        self.total += here.price;
        visit [-->];
    }

    # Subtype-specific handling: `here` is correctly typed in each ability
    can show_book with Book entry {
        print(f"  -> Book: '{here.title}' by {here.author}");
    }
    can show_magazine with Magazine entry {
        print(f"  -> Magazine: '{here.title}' Issue #{here.issue}");
    }
    can show_electronics with Electronics entry {
        print(f"  -> Electronics: {here.name}, warranty {here.warranty_years}yr");
    }
}
