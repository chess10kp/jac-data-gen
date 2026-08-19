node Product {
    has name: str;
    has category: str;
    has price: float;
}
node Customer {
    has name: str;
}
edge Purchased {
    has rating: int;
    has date: str;
}
walker RecommendProducts {
    has min_rating: int = 4;
    has recommendations: list = [];
    can start with Root entry;
    can find_recommendations with Customer entry {
        print(f"Finding recommendations for {here.name}...");
        purchases = [here ->:Purchased:rating >= self.min_rating:->];
        for product in purchases {
            similar = [product <-:Purchased:<- ->:Purchased:rating >= self.min_rating:->];
            for similar_product in similar {
                if similar_product not in purchases {
                    if similar_product.name not in self.recommendations {
                        self.recommendations.append(similar_product.name);
                    }
                }
            }
        }
        disengage;
    }
}
impl RecommendProducts.start {
    visit [-->];
}
with entry {
    alice = Customer(name="Alice");
    bob = Customer(name="Bob");
    laptop = Product(name="Laptop", category="Electronics", price=999.99);
    mouse = Product(name="Mouse", category="Electronics", price=29.99);
    keyboard = Product(name="Keyboard", category="Electronics", price=79.99);
    headphones = Product(name="Headphones", category="Electronics", price=149.99);
    root ++> alice;
    root ++> bob;
    alice +>:Purchased(rating=5, date="2024-01-15"):+> laptop;
    alice +>:Purchased(rating=4, date="2024-01-20"):+> mouse;
    bob +>:Purchased(rating=5, date="2024-02-01"):+> laptop;
    bob +>:Purchased(rating=5, date="2024-02-05"):+> keyboard;
    bob +>:Purchased(rating=4, date="2024-02-10"):+> headphones;
    recommender = RecommendProducts(min_rating=4);
    alice spawn recommender;
    print(f"Recommended for Alice: {recommender.recommendations}");
}
