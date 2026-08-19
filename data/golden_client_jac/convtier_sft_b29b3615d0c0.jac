node Post {}
edge TollGate { has fee: int; }

walker FeeProd {
    has prod: int = 1;
    can pay with TollGate entry { self.prod *= here.fee; }
    can advance with Post entry { visit [edge -->]; }
}

def edge_weight_product(spec: dict) -> int {
    tolls: list = list(spec["tolls"]);
    posts: list = [Post() for _ in range(len(tolls) + 1)];
    k: int = len(tolls);
    while k > 0 {
        posts[k - 1] +>:TollGate(fee=int(tolls[k - 1])):+> posts[k];
        k -= 1;
    }
    return (posts[0] spawn FeeProd()).prod;
}

with entry {
    print(edge_weight_product({'tolls': [2, 3, 4]}));
}
