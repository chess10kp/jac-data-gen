walker ShoppingCart {
    can process_item with Product entry {
        print(f"Processing {type(here).__name__}...");

        # Each subtype gets its own block
        ->Book{print(f"  -> Book: '{here.title}' by {here.author}");}
        ->Magazine{print(f"  -> Magazine: '{here.title}' Issue #{here.issue}");}
        ->Electronics{print(f"  -> Electronics: {here.name}, warranty {here.warranty_years}yr");}

        self.total += here.price;
        visit [-->];
    }
}
