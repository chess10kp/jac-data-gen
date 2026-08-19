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
    can find_recommendations with Customer entry {
        purchases = [here ->:Purchased:rating >= self.min_rating:->];
        # ... find similar products next
        disengage;
    }
}
