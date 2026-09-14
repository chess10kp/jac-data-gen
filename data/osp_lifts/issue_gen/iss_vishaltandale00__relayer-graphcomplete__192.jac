"""Recursive semantic graph judge for vishaltandale00/relayer-graphcomplete#192."""

node Layer {
    has lid: str;
    has title: str;
}

node JudgeNode {
    has nid: str;
    has content: str;
    has last_result: NodeResult | None = None;
}

node Action {
    has kind: str;
    has destination: str;
    has grade: int = 0;
}

node NodeResult {
    has node_id: str;
    has scores: list[int] = [0, 0, 0];
    has semantics: list[str] = ["", "", ""];
    has summary: str = "";
    has evidence: list[str] = [];
    has preferred_action: str = "stop";
    has delivery_score: int = 0;
}

node LayerResult {
    has layer_id: str;
    has scores: list[int] = [0, 0, 0];
    has semantics: list[str] = ["", "", ""];
    has summary: str = "";
    has evidence: list[str] = [];
    has node_ids: list[str] = [];
    has node_scores: list[list[int]] = [];
    has node_semantics: list[list[str]] = [];
}

edge Contains {}
edge Authored {}
edge Expands {}
edge References {}
edge Invokes {}

def make_layer(lid: str, title: str) -> Layer {
    return Layer(lid=lid, title=title);
}

def add_node(layer: Layer, nid: str, content: str) -> JudgeNode {
    node_item = JudgeNode(nid=nid, content=content);
    layer +>:Contains:+> node_item;
    return node_item;
}

def add_action(node_item: JudgeNode, kind: str, destination: str) -> Action {
    action_item = Action(kind=kind, destination=destination);
    node_item +>:Authored:+> action_item;
    return action_item;
}

def link_action(a: Action, child: Layer) {
    if a.kind == "expand" {
        a +>:Expands:+> child;
    }
    if a.kind == "reference" {
        a +>:References:+> child;
    }
    if a.kind == "invoke" {
        a +>:Invokes:+> child;
    }
}

walker GradeNode {
    has claimed: dict[str, bool] = {};
    has result: NodeResult | None = None;

    can grade_node with JudgeNode entry {
        claim_key: str = "N:" + here.nid;
        if claim_key in self.claimed {
            skip;
        }
        self.claimed[claim_key] = true;
        print("grading node " + here.nid);

        ranked: list[str] = [];
        if len(here.content) > 30 {
            ranked.append("expand");
            ranked.append("reference");
            ranked.append("invoke");
            ranked.append("stop");
        }
        if len(here.content) <= 30 {
            ranked.append("stop");
            ranked.append("reference");
            ranked.append("expand");
            ranked.append("invoke");
        }

        authored: list[str] = [];
        evidence: list[str] = [];
        recursive_score: int = 4;
        delivery_score: int = 0;
        for a in [here ->:Authored:->][?:Action] {
            authored.append(a.kind);
            a.grade = 2;
            if len(a.destination) > 0 {
                a.grade = 4;
                delivery_score = 4;
            }
            evidence.append(a.kind + ":" + a.destination);

            if a.kind == "expand" {
                for child in [a ->:Expands:->][?:Layer] {
                    child_w = child spawn GradeLayer(claimed=self.claimed);
                    if child_w.result != None {
                        if child_w.result.scores[2] < recursive_score {
                            recursive_score = child_w.result.scores[2];
                        }
                        evidence.append(child_w.result.summary);
                    }
                }
            }
            if a.kind == "reference" {
                for child in [a ->:References:->][?:Layer] {
                    ref_w = child spawn GradeLayer(claimed=self.claimed);
                    if ref_w.result != None {
                        if ref_w.result.scores[2] < recursive_score {
                            recursive_score = ref_w.result.scores[2];
                        }
                        evidence.append(ref_w.result.summary);
                    }
                }
            }
        }

        allocation_score: int = 4;
        if ranked[0] != "stop" {
            if len(authored) == 0 {
                allocation_score = 1;
            }
        }
        if ranked[0] == "stop" {
            if len(authored) > 0 {
                allocation_score = 2;
            }
        }

        content_score: int = 0;
        if len(here.content) > 0 {
            content_score = 4;
        }
        semantics: list[str] = [
            "visible content graded",
            "preferred action is " + ranked[0],
            "child LayerResults compressed bottom-up"
        ];
        self.result = NodeResult(
            node_id=here.nid,
            scores=[content_score, allocation_score, recursive_score],
            semantics=semantics,
            summary="node " + here.nid + " preferred " + ranked[0],
            evidence=evidence,
            preferred_action=ranked[0],
            delivery_score=delivery_score
        );
        here.last_result = self.result;
    }
}

walker GradeLayer {
    has claimed: dict[str, bool] = {};
    has result: LayerResult | None = None;

    can grade_layer with Layer entry {
        claim_key: str = "L:" + here.lid;
        if claim_key in self.claimed {
            skip;
        }
        self.claimed[claim_key] = true;
        print("grading layer " + here.lid);

        scores: list[int] = [4, 4, 4];
        semantics: list[str] = [
            "strongest visible node signal",
            "strongest allocation signal",
            "strongest recursive signal"
        ];
        evidence: list[str] = [];
        node_ids: list[str] = [];
        node_scores: list[list[int]] = [];
        node_semantics: list[list[str]] = [];

        for node_item in [here ->:Contains:->][?:JudgeNode] {
            node_w = node_item spawn GradeNode(claimed=self.claimed);
            if node_w.result != None {
                node_ids.append(node_w.result.node_id);
                node_scores.append(node_w.result.scores);
                node_semantics.append(node_w.result.semantics);
                evidence.append(node_w.result.summary);
                if node_w.result.scores[0] < scores[0] {
                    scores[0] = node_w.result.scores[0];
                    semantics[0] = node_w.result.semantics[0];
                }
                if node_w.result.scores[1] < scores[1] {
                    scores[1] = node_w.result.scores[1];
                    semantics[1] = node_w.result.semantics[1];
                }
                if node_w.result.scores[2] < scores[2] {
                    scores[2] = node_w.result.scores[2];
                    semantics[2] = node_w.result.semantics[2];
                }
            }
        }

        if len(node_ids) == 0 {
            scores = [0, 0, 0];
            semantics = ["empty layer", "no authored allocation", "no recursive signal"];
        }
        self.result = LayerResult(
            layer_id=here.lid,
            scores=scores,
            semantics=semantics,
            summary="layer " + here.lid + " compressed " + str(len(node_ids)) + " nodes",
            evidence=evidence,
            node_ids=node_ids,
            node_scores=node_scores,
            node_semantics=node_semantics
        );
    }
}

walker LocateLayer {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: Layer | None = None;

    can locate with Layer entry {
        claim_key: str = "L:" + here.lid;
        if claim_key in self.claimed {
            skip;
        }
        self.claimed[claim_key] = true;
        print("inspecting layer " + here.lid);
        if here.lid == self.wanted {
            self.found = here;
            skip;
        }
        for node_item in [here ->:Contains:->][?:JudgeNode] {
            for a in [node_item ->:Authored:->][?:Action] {
                for child in [a ->:Expands:->][?:Layer] {
                    visit :0: [child];
                }
                for child in [a ->:References:->][?:Layer] {
                    visit :0: [child];
                }
            }
        }
    }
}

def grade_layer(root_node: Layer) -> LayerResult {
    claims: dict[str, bool] = {};
    w = root_node spawn GradeLayer(claimed=claims);
    if w.result != None {
        return w.result;
    }
    return LayerResult(layer_id=root_node.lid, scores=[0, 0, 0]);
}

def find_layer(root_node: Layer, wanted: str) -> Layer | None {
    claims: dict[str, bool] = {};
    w = root_node spawn LocateLayer(wanted=wanted, claimed=claims);
    return w.found;
}
