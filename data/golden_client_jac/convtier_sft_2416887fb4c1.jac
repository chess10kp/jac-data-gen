obj MatrixStack {
    has proj: list = [];
    has mv: list = [];
    has mode: int = 0;

    def current -> list {
        return self.proj if self.mode == 0x1701 else self.mv;
    }
}

def active_matrix(state: dict) -> list {
    return MatrixStack(proj=state["proj"], mv=state["mv"], mode=state["mode"]).current();
}

with entry {
    print(active_matrix({'proj': [2.0, 0.0, 0.0, 1.0], 'mv': [1.0, 5.0, 5.0, 1.0], 'mode': 5889}));
}
