# agents/fca_mapper.jac

import from byllm.llm { Model }
import from nodes.data_nodes {
    FalsityNode,
    ScientorNode,
    MaterialityNode,
    CausationNode,
    EvidenceNode,
    TimelineNode
}
import from helpers { extract_provider_names, check_oig_leie, parse_json }

glob llm = Model(model_name="claude-haiku-4-5-20251001");

node FCAMapperAgent {

    """
    Map each piece of evidence to one of the four False Claims Act
    legal elements: Falsity, Scienter, Materiality, or Causation.
    Return a JSON string with keys:
      - "falsity": {"evidence": [str], "type": "factual"|"legal", "score": 0.0-1.0}
      - "scienter": {"evidence": [str], "type": "actual"|"deliberate_ignorance"|"reckless", "score": 0.0-1.0}
      - "materiality": {"evidence": [str], "relied": bool, "score": 0.0-1.0}
      - "causation": {"evidence": [str], "chain": str, "score": 0.0-1.0}
    If oig_match is True, score scienter minimum 0.9.
    Return only valid JSON string. No other text.
    """
    def map_to_fca_elements(
        evidence: list[dict],
        timeline_events: list[dict],
        oig_match: bool
    ) -> str by llm();

    can run with entry {
        print("FCA Mapper ability firing!");

        evidence: list[dict] = [];
        for e in [root -->][?:EvidenceNode] {
            evidence.append({
                "desc": e.description,
                "source": e.source_doc
            });
        }

        timeline_events: list[dict] = [];
        for t in [root -->][?:TimelineNode] {
            timeline_events = t.events;
        }

        providers = extract_provider_names(evidence);
        oig_match = check_oig_leie(providers, "data/oig_leie.csv");

        raw = self.map_to_fca_elements(
            evidence,
            timeline_events,
            oig_match
        );
        mapping = parse_json(raw);

        f_data = mapping.get("falsity", {});
        f_node = FalsityNode();
        f_node.evidence_list  = f_data.get("evidence", []);
        f_node.falsity_type   = f_data.get("type", "factual");
        f_node.strength_score = float(f_data.get("score", 0.0));
        root ++> f_node;

        s_data = mapping.get("scienter", {});
        s_node = ScientorNode();
        s_node.evidence_list  = s_data.get("evidence", []);
        s_node.knowledge_type = s_data.get("type", "actual");
        s_node.strength_score = float(s_data.get("score", 0.0));
        root ++> s_node;

        m_data = mapping.get("materiality", {});
        m_node = MaterialityNode();
        m_node.evidence_list     = m_data.get("evidence", []);
        m_node.government_relied = m_data.get("relied", False);
        m_node.strength_score    = float(m_data.get("score", 0.0));
        root ++> m_node;

        c_data = mapping.get("causation", {});
        c_node = CausationNode();
        c_node.evidence_list  = c_data.get("evidence", []);
        c_node.causal_chain   = c_data.get("chain", "");
        c_node.strength_score = float(c_data.get("score", 0.0));
        root ++> c_node;

        visitor.mapping_done = True;
        print("FCA mapping complete!");
        print("Falsity score: " + str(f_node.strength_score));
        print("Scienter score: " + str(s_node.strength_score));
        print("Materiality score: " + str(m_node.strength_score));
        print("Causation score: " + str(c_node.strength_score));
    }
}
