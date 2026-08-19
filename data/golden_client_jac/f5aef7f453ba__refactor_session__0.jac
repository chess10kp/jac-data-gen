walker RecommendProducts {
    has min_rating: int = 4;
    has recommendations: list = [];
    can start with Root entry;
    can find_recommendations with Customer entry;
}
impl RecommendProducts.start { visit [-->]; }
impl RecommendProducts.find_recommendations {
    # ... body with disengage;
}
