# iss_TheWizardsCode__Tableau-Card-Engine__790.jac

node Scene {
    has sid: str;
}

node Card {
    has cid: str;
    has svg: str;
    has texture_key: str;
    has depth: int = 0;
}

node Overlay {
    has oid: str;
    has depth: int = 0;
}

edge SceneCard {}
edge SceneOverlay {}
edge OverlayCard {}

obj TextureStore {
    has textures: dict[str, str] = {};
}

walker NativeRender {
    has claimed: dict[str, bool] = {};
    has candidates: list[str] = [];
    has blocked: dict[str, bool] = {};

    can step_scene with Scene entry {
        scene_key = "scene:" + here.sid;
        if scene_key in self.claimed {
            skip;
        }
        self.claimed[scene_key] = True;
        print("scene " + here.sid);
        for card in [here ->:SceneCard:->][?:Card] {
            visit :0: [card];
        }
        for overlay in [here ->:SceneOverlay:->][?:Overlay] {
            visit :0: [overlay];
        }
    }

    can step_card with Card entry {
        card_key = "card:" + here.cid;
        if card_key in self.claimed {
            skip;
        }
        self.claimed[card_key] = True;
        self.candidates.append(here.cid);
        print("card " + here.cid);
    }

    can step_overlay with Overlay entry {
        overlay_key = "overlay:" + here.oid;
        if overlay_key in self.claimed {
            skip;
        }
        self.claimed[overlay_key] = True;
        print("overlay " + here.oid);
        for card in [here ->:OverlayCard:->][?:Card] {
            if here.depth > card.depth {
                self.blocked[card.cid] = True;
            }
            visit :0: [card];
        }
    }
}

def new_texture_store() -> TextureStore {
    return TextureStore();
}

def new_scene(name: str) -> Scene {
    return Scene(sid=name);
}

def add_card(store: TextureStore, scene: Scene, card_id: str, svg: str,
             texture_key: str, depth: int = 0) -> Card {
    card = Card(cid=card_id, svg=svg, texture_key=texture_key, depth=depth);
    scene +>:SceneCard:+> card;
    store.textures[texture_key] = svg;
    return card;
}

def add_overlay(scene: Scene, overlay_id: str, depth: int) -> Overlay {
    overlay = Overlay(oid=overlay_id, depth=depth);
    scene +>:SceneOverlay:+> overlay;
    return overlay;
}

def cover(overlay: Overlay, card: Card) -> None {
    overlay +>:OverlayCard:+> card;
}

def render_native(scene: Scene) -> list[str] {
    w = scene spawn NativeRender(claimed={}, candidates=[], blocked={});
    visible: list[str] = [];
    for card_id in w.candidates {
        if card_id not in w.blocked {
            visible.append(card_id);
        }
    }
    return sorted(visible);
}

def invalidate_texture(store: TextureStore, texture_key: str) -> bool {
    if texture_key not in store.textures {
        return False;
    }
    store.textures.pop(texture_key);
    return True;
}

test "diamond_revisit_is_occluded" {
    store = new_texture_store();
    scene = new_scene("main");
    shared = add_card(store, scene, "shared", "<svg/>", "shared");
    add_card(store, scene, "visible", "<svg/>", "visible");
    low = add_overlay(scene, "low", 1);
    high = add_overlay(scene, "high", 5);
    cover(low, shared);
    cover(high, shared);
    assert (render_native(scene) == ["visible"]);
}

test "unknown_texture_id_is_tolerated" {
    store = new_texture_store();
    scene = new_scene("main");
    add_card(store, scene, "card", "<svg/>", "texture");
    assert (invalidate_texture(store, "missing") == False);
    assert (invalidate_texture(store, "texture") == True);
    assert (invalidate_texture(store, "texture") == False);
}

test "orphan_overlay_does_not_hide_cards" {
    store = new_texture_store();
    scene = new_scene("main");
    add_overlay(scene, "orphan", 10);
    add_card(store, scene, "solo", "<svg/>", "solo");
    assert (render_native(scene) == ["solo"]);
}

test "empty_scene_renders_nothing" {
    scene = new_scene("empty");
    assert (render_native(scene) == []);
}
