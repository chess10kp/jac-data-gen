# iss_69420pm__ai-learning-support-test__116.jac

node Material {
    has material_id: str;
    has title: str;
}

node KC {
    has slug: str;
    has title: str;
    has pacer: str = "concept";
    has bloom: str = "understand";
}

node Exercise {
    has exercise_id: str;
    has prompt: str;
}

edge Contains {}
edge DependsOn {
    has confidence: float = 0.0;
}
edge SupportsExercise {}

obj KnowledgeGraph {
    has concepts: dict[str, KC] = {};
}

walker PrerequisiteWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with KC entry {
        if here.slug in self.claimed {
            skip;
        }
        self.claimed[here.slug] = True;
        self.found.append(here.slug);
        print(here.slug);
        for kid in [here ->:DependsOn:->][?:KC] {
            visit :0: [kid];
        }
    }
}

def newKnowledgeGraph() -> KnowledgeGraph {
    return KnowledgeGraph();
}

def newMaterial(material_id: str, title: str) -> Material {
    return Material(material_id=material_id, title=title);
}

def newKC(
    slug: str,
    title: str,
    pacer: str = "concept",
    bloom: str = "understand"
) -> KC {
    return KC(slug=slug, title=title, pacer=pacer, bloom=bloom);
}

def newExercise(exercise_id: str, prompt: str) -> Exercise {
    return Exercise(exercise_id=exercise_id, prompt=prompt);
}

def registerConcept(graph: KnowledgeGraph, concept: KC) {
    graph.concepts[concept.slug] = concept;
}

def getPrerequisiteChain(start: KC) -> list[str] {
    w = start spawn PrerequisiteWalker(claimed={});
    return sorted(w.found);
}

def addPrerequisite(
    advanced: KC,
    prerequisite: KC,
    confidence: float = 0.0
) {
    if advanced.slug == prerequisite.slug {
        return;
    }
    if advanced.slug in getPrerequisiteChain(prerequisite) {
        return;
    }
    advanced +>:DependsOn(confidence=confidence):+> prerequisite;
}

def addPrerequisiteById(
    graph: KnowledgeGraph,
    advanced_id: str,
    prerequisite_id: str,
    confidence: float = 0.0
) {
    if advanced_id not in graph.concepts {
        return;
    }
    if prerequisite_id not in graph.concepts {
        return;
    }
    addPrerequisite(
        graph.concepts[advanced_id],
        graph.concepts[prerequisite_id],
        confidence
    );
}

def linkMaterialConcept(material: Material, concept: KC) {
    material +>:Contains:+> concept;
}

def linkExercise(concept: KC, exercise: Exercise) {
    concept +>:SupportsExercise:+> exercise;
}

def getMaterialConcepts(material: Material) -> list[str] {
    slugs: list[str] = [];
    for concept in [material ->:Contains:->][?:KC] {
        slugs.append(concept.slug);
    }
    return sorted(slugs);
}

def getExercisesForKc(concept: KC) -> list[str] {
    exercise_ids: list[str] = [];
    for exercise in [concept ->:SupportsExercise:->][?:Exercise] {
        exercise_ids.append(exercise.exercise_id);
    }
    return sorted(exercise_ids);
}

def getPrerequisiteChainById(
    graph: KnowledgeGraph,
    slug: str
) -> list[str] {
    if slug not in graph.concepts {
        return [];
    }
    return getPrerequisiteChain(graph.concepts[slug]);
}

test "diamond revisit is claim safe" {
    a = newKC("a", "A");
    b = newKC("b", "B");
    c = newKC("c", "C");
    d = newKC("d", "D");

    addPrerequisite(a, c, 0.9);
    addPrerequisite(a, b, 0.8);
    addPrerequisite(c, d, 0.9);
    addPrerequisite(b, d, 0.8);

    chain = getPrerequisiteChain(a);
    assert (chain == ["a", "b", "c", "d"]);
}

test "unknown ids are tolerated" {
    graph = newKnowledgeGraph();

    addPrerequisiteById(graph, "missing", "also-missing");
    assert (getPrerequisiteChainById(graph, "missing") == []);
}

test "material and exercise links are indexed" {
    material = newMaterial("m1", "Calculus Notes");
    limits = newKC("limits", "Limits");
    derivatives = newKC("derivatives", "Derivatives");
    exercise = newExercise("ex1", "Compute a derivative.");

    linkMaterialConcept(material, derivatives);
    linkMaterialConcept(material, limits);
    linkExercise(derivatives, exercise);

    assert (getMaterialConcepts(material) == ["derivatives", "limits"]);
    assert (getExercisesForKc(derivatives) == ["ex1"]);
}

test "cycle attempt is rejected without truncating traversal" {
    a = newKC("a", "A");
    b = newKC("b", "B");

    addPrerequisite(a, b);
    addPrerequisite(b, a);

    assert (getPrerequisiteChain(a) == ["a", "b"]);
}
