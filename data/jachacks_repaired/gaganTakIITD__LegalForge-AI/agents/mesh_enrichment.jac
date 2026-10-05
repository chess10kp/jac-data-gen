"""Mesh enrichment walker — classify clauses and weave reference/modifies edges."""

import from ..graph.nodes { Contract, Clause, references, modifies }
import from ..tools.clause_classifier { classify_clause }
import from ..tools.graph_mesh { extract_section_refs, extract_modifies_target }
walker MeshEnrichmentWalker {
    has reference_edges: int = 0;
    has modifies_edges: int = 0;
    has all_clauses: list = [];

    can start with Contract entry {
        self.all_clauses = [-->[?Clause]];
        visit [-->];
    }

    can enrich with Clause entry {
        if not here.clause_kind {
            here.clause_kind = classify_clause(here.text, here.section);
        }

        all_clauses = self.all_clauses;
        for ref_id in extract_section_refs(here.text) {
            for tgt in all_clauses {
                if tgt.clause_id == ref_id and tgt.clause_id != here.clause_id {
                    here +>:references(context=f"references Section {ref_id}"):+> tgt;
                    self.reference_edges += 1;
                }
            }
        }
        for ref_id in extract_modifies_target(here.text) {
            for tgt in all_clauses {
                if tgt.clause_id == ref_id and tgt.clause_id != here.clause_id {
                    here +>:modifies(scope="limits"):+> tgt;
                    self.modifies_edges += 1;
                }
            }
        }
        visit [-->];
    }

    can finish with Contract exit {
        report {
            "agent": "MeshEnrichmentWalker",
            "reference_edges": self.reference_edges,
            "modifies_edges": self.modifies_edges
        };
    }
}
