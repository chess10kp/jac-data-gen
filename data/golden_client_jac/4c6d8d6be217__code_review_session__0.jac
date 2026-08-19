edge Friend {
    has since: int;
    has strength: float = 1.0;
}

edge Follows { }  # Edge with no data

edge Weighted {
    has weight: float;

    def get_normalized(max_weight: float) -> float {
        if max_weight == 0.0 {
            return 0.0;
        }
        return self.weight / max_weight;
    }
}
