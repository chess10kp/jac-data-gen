import graph.nodes;
import graph.edges;
import from walkers.seed_graph { seed_graph }
import from walkers.get_graph_data { get_graph_data }
import from walkers.parse_rx { parse_rx }
import from walkers.interaction_walk { interaction_walk }
import from walkers.condition_walk { condition_walk }
import from walkers.report_walker { report_walker }
import from walkers.drug_stats { drug_stats }

with entry {
    root spawn seed_graph();
}
