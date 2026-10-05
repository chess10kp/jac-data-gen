"""SybilScope — On-Chain Sybil Detector using JAC Walker + LLM Reasoning

Strategy:
1. Group all wallets into funding + Louvain clusters sorted by suspicion
2. Classify cluster-by-cluster from the most suspicious outward
3. Early-stop when a cluster shows clean behavior
"""

import from data_fetcher {
    fetch_wallet_data,
    compute_timing_stats,
    compute_entropy_features,
    find_common_funder,
    compute_behavior_similarity,
    llm_classify_sybil,
    llm_classify_cluster,
    llm_classify_cluster_enriched,
    get_cache_path,
    build_funding_clusters,
    build_louvain_clusters,
    merge_clusters,
    detect_chain,
    detect_amount_anomaly,
    detect_tx_count_fingerprint,
    build_funding_tree,
    post_llm_override,
    refine_louvain_clusters,
    build_json_output,
    find_sibling_clusters,
    check_temporal_cohort,
    compare_legit_baseline
}
import json;

# ---- Data Types ----

node Wallet {
    has address: str,
        created_at: str = "",
        tx_count: int = 0,
        first_funder: str = "",
        protocol_interactions: list[str] = [],
        operation_intervals: list[float] = [],
        label: str = "unknown",
        sybil_proximity: float = 0.0,
        hour_entropy: float = 0.0,
        dow_entropy: float = 0.0,
        burst_score: float = 0.0,
        ngram_entropy: float = 0.0;
}

edge Transfer {
    has amount: float = 0.0,
        timestamp: str = "",
        token: str = "ETH",
        tx_count: int = 1,
        total_amount: float = 0.0,
        first_ts: str = "",
        last_ts: str = "";
}

node Cluster {
    has funder: str = "",
        wallets: list[str] = [],
        priority: int = 0;
}

enum SybilRisk {
    CLEAN,
    SUSPICIOUS,
    LIKELY_SYBIL,
    CONFIRMED_SYBIL
}

sem SybilRisk.CLEAN = "Wallet shows normal, organic transaction patterns with diverse protocol interactions, varied timing, and independent funding sources";
sem SybilRisk.SUSPICIOUS = "One or two anomalous indicators present but inconclusive — could be a power user or bot";
sem SybilRisk.LIKELY_SYBIL = "Multiple sybil indicators: shared funder with other wallets, clustered activity timing, overlapping protocol interactions";
sem SybilRisk.CONFIRMED_SYBIL = "High-confidence sybil: identical funding source across many wallets, machine-precision timing gaps, minimum qualifying interactions only";

obj SybilVerdict {
    has address: str = "",
        risk: SybilRisk = SybilRisk.CLEAN,
        confidence: float = 0.0,
        evidence: list[str] = [],
        reasoning: str = "";
}

enum InvestigationAction {
    EXPAND_FUNDER_TREE,
    FIND_SIBLINGS,
    CHECK_TEMPORAL_COHORT,
    COMPARE_LEGIT_BASELINE,
    FINALIZE
}

sem InvestigationAction.EXPAND_FUNDER_TREE = "Dig deeper up the funding chain (to depth 5) to trace the original money source";
sem InvestigationAction.FIND_SIBLINGS = "Look for sibling clusters sharing the same funder or overlapping wallets — reveals wider sybil network";
sem InvestigationAction.CHECK_TEMPORAL_COHORT = "Check if wallets were created within a narrow time window (bot farm creation burst)";
sem InvestigationAction.COMPARE_LEGIT_BASELINE = "Compare cluster feature distribution against legitimate wallet baseline for anomaly";
sem InvestigationAction.FINALIZE = "Enough evidence gathered — stop investigating and finalize verdicts";

obj ActionChoice {
    has action: InvestigationAction = InvestigationAction.FINALIZE,
        rationale: str = "";
}

obj WalletFeatures {
    has address: str,
        tx_count: int,
        first_funder: str,
        avg_timing_gap_seconds: float,
        timing_std_seconds: float,
        num_protocols: int,
        has_common_funder: bool,
        behavior_similarity_score: float,
        sybil_proximity: float = 0.0,
        hour_entropy: float = 0.0,
        dow_entropy: float = 0.0,
        burst_score: float = 0.0,
        ngram_entropy: float = 0.0;
}

obj TransferRecord {
    """Flat projection of a Transfer edge between two cluster-internal wallets.
    Passed to `by llm()` so the LLM can see which wallets are tx-connected
    to which — sub-graph reasoning, not flat-feature reasoning."""
    has from_addr: str = "",
        to_addr: str = "",
        tx_count: int = 0,
        total_amount_eth: float = 0.0,
        first_ts: str = "",
        last_ts: str = "";
}

# ---- by llm() declaration (JAC paradigm primary classifier) ----

def classify_cluster_jac(
    wallets: list[WalletFeatures],
    transfers: list[TransferRecord],
    cluster_size: int,
    common_funder: str,
    chain_detected: bool,
    chain_height: int,
    amount_anomaly: bool,
    dominant_amount: float,
    tx_fingerprint: bool,
    dominant_tx_count: int,
    funding_tree_depth: int
) -> list[SybilVerdict]
by llm();

sem classify_cluster_jac = """
Analyze this cluster of blockchain wallets for Sybil attack. You receive:
  - `wallets`: per-wallet features (the nodes)
  - `transfers`: the directed Transfer edges BETWEEN cluster wallets (the edges)

This is a sub-graph. USE the edges — not just the per-wallet features:
  - Dense internal connectivity (many transfers among cluster members) = sybil ring
  - A wallet with high in/out degree WITHIN the cluster is a hub (often the funder-proxy)
  - Cycles (A->B->C->A) are near-certain sybil laundering patterns
  - If `transfers` is empty while wallets share a funder, it's a "fresh fan-out" pattern
    (funder → N wallets, wallets not yet transacting with each other) — still sybil

Return one verdict per wallet in the same order as the wallets input.

CRITICAL: Sharing a funder with multiple wallets is STRONG evidence of Sybil — real users
almost never share the same first funder by coincidence. Err on the side of flagging.

ENTROPY SIGNALS (bot vs human activity fingerprints):
- `hour_entropy` (max 4.58): low values mean txs cluster in narrow hours of the day — bot
  on a schedule. Humans spread across waking hours (>= 3.0 typical).
- `dow_entropy` (max 2.81): low means concentrated in 1-2 days per week. Humans >= 2.0.
- `burst_score` (unbounded): std/mean of inter-tx gaps. Bots show near-uniform periodic
  cadence (burst_score < 0.5). Real users are bursty (>= 1.0).
- `ngram_entropy`: entropy of protocol-interaction bigrams. Low = same protocol sequence
  template repeated (bot script). High = varied behavior.
Use these as corroborating evidence: LOW hour_entropy + LOW burst_score together are a
strong bot fingerprint even without a shared funder.

STRONG GRAPH SIGNAL: `sybil_proximity` is a hop-decayed label-propagation score from
known sybil seeds along the Transfer graph (values accumulate across multiple seeds, so
the scale is unbounded — compare magnitudes relative to peers). High proximity (>= 0.5)
means the wallet directly trades with known sybils — strong positive evidence, upgrade
the verdict. proximity == 0 means ONLY that the wallet has no tx edge to any known seed
in this dataset; it does NOT indicate legitimacy (the tx graph is sparse and many real
sybils operate through fresh funnels). Treat high proximity as a strong upgrade signal,
but do not downgrade verdicts just because proximity is low.

CLASSIFICATION RULES:
- CONFIRMED_SYBIL: shared funder + (chain pattern OR amount anomaly OR identical behavior OR identical tx counts)
- LIKELY_SYBIL: shared funder + any one additional indicator (low tx count, similar timing, protocol overlap)
- SUSPICIOUS: shared funder alone, or single weak indicator
- CLEAN: independent funding AND diverse behavior

Provide 2-3 specific evidence items and a brief reasoning for each wallet.
""";

def pick_next_action(
    low_confidence_count: int,
    cluster_size: int,
    evidence_collected: list[str],
    actions_already_taken: list[str],
    budget_remaining: int
) -> ActionChoice
by llm();

sem pick_next_action = """
You are agentically investigating a cluster of wallets with uncertain sybil verdicts.
Pick the MOST informative next action to clarify the verdict.

Rules:
- Do NOT repeat an action already in actions_already_taken
- Prefer FINALIZE when budget_remaining <= 1 and you already have 2+ pieces of evidence
- Prefer FIND_SIBLINGS early (reveals network scope cheaply)
- Prefer CHECK_TEMPORAL_COHORT if cluster_size >= 5 (bot farms burst-create)
- Prefer COMPARE_LEGIT_BASELINE when timing/protocol signals are ambiguous
- Prefer EXPAND_FUNDER_TREE if no funder-tree evidence collected yet

Provide action and a brief rationale (under 15 words).
""";

def reflect_on_evidence(
    wallets: list[WalletFeatures],
    new_evidence: list[str]
) -> list[SybilVerdict]
by llm();

sem reflect_on_evidence = """
After agentic investigation, new evidence has been gathered. Produce updated verdicts for
each wallet incorporating this evidence. Use the same CLASSIFICATION RULES as the primary
classifier (shared funder + indicators → higher risk). Return one verdict per wallet in
input order. If new evidence strengthens sybil signals, upgrade risk AND confidence.
""";

# ---- Walkers ----

walker DataCollector {
    """Traverse graph and collect on-chain data for each wallet node."""
    has visited: set = set(),
        wallet_data: list[dict] = [];

    can start with entry {
        visit [-->];
    }

    can collect with Wallet entry {
        if here.address in self.visited {
            disengage;
        }
        self.visited.add(here.address);

        data = fetch_wallet_data(here.address);
        here.created_at = data["created_at"];
        here.tx_count = data["tx_count"];
        here.first_funder = data["first_funder"];
        here.protocol_interactions = data["protocol_interactions"];
        here.operation_intervals = data["operation_intervals"];
        here.label = data["label"];

        self.wallet_data.append(data);
        visit [-->];
    }
}

walker SybilJudge {
    """Collect features for wallets in a cluster, then batch-classify via single LLM call."""
    has wallet_data: list[dict] = [],
        cluster_data: list[dict] = [],
        features: list[dict] = [],
        labels: list[str] = [],
        verdicts: list[dict] = [],
        _has_common: bool = False;

    can start with entry {
        visit [-->];
    }

    can collect_features with Wallet entry {
        if here.tx_count == 0 {
            visit [-->];
            disengage;
        }

        timing = compute_timing_stats(here.operation_intervals);

        # Compute common funder once and cache it
        if not self.features {
            self._has_common = find_common_funder(self.wallet_data) is not None;
        }

        # Behavior similarity with cluster peers using existing data
        max_similarity = 0.0;
        for wd in self.cluster_data {
            if wd["address"] != here.address {
                sim = compute_behavior_similarity(
                    {"protocol_interactions": here.protocol_interactions}, wd
                );
                if sim > max_similarity {
                    max_similarity = sim;
                }
            }
        }

        self.features.append({
            "address": here.address,
            "tx_count": here.tx_count,
            "first_funder": here.first_funder,
            "avg_timing_gap_seconds": timing["avg_gap"],
            "timing_std_seconds": timing["std_gap"],
            "num_protocols": len(here.protocol_interactions),
            "has_common_funder": self._has_common,
            "behavior_similarity_score": max_similarity,
            "sybil_proximity": here.sybil_proximity,
            "hour_entropy": here.hour_entropy,
            "dow_entropy": here.dow_entropy,
            "burst_score": here.burst_score,
            "ngram_entropy": here.ngram_entropy
        });
        self.labels.append(here.label);

        visit [-->];
    }
}

walker GraphBuilder {
    """Materialize Transfer edges between tracked Wallet nodes.
    Two-phase: phase='index' builds addr->node map; phase='connect' emits edges.
    One aggregated Transfer edge per unique (from, to) pair carrying tx_count,
    total_amount, first_ts, last_ts — sybil clusters show up as dense sub-graphs."""
    has tx_by_addr: dict[str, list] = {},
        addr_to_node: dict[str, Wallet] = {},
        phase: str = "index",
        edges_created: int = 0,
        visited: set = set();

    can start with entry {
        visit [-->];
    }

    can step with Wallet entry {
        if here.address in self.visited {
            disengage;
        }
        self.visited.add(here.address);

        if self.phase == "index" {
            self.addr_to_node[here.address.lower()] = here;
            visit [-->];
            return;
        }

        # phase == "connect" — aggregate this wallet's outgoing txs by counterparty
        # (parallel typed dicts keep the type-checker happy without a nested dict)
        my_addr = here.address.lower();
        counts: dict[str, int] = {};
        totals: dict[str, float] = {};
        first_ts: dict[str, str] = {};
        last_ts: dict[str, str] = {};
        for tx in self.tx_by_addr.get(here.address, []) {
            to_raw: str = str(tx.get("to", "") or "");
            to_addr: str = to_raw.lower();
            if not to_addr or to_addr == my_addr {
                continue;
            }
            if to_addr not in self.addr_to_node {
                continue;
            }
            amt: float = 0.0;
            try {
                amt = float(tx.get("value", "0")) / 1e18;
            } except Exception {
                amt = 0.0;
            }
            ts: str = str(tx.get("timeStamp", "") or "");
            if to_addr not in counts {
                counts[to_addr] = 0;
                totals[to_addr] = 0.0;
                first_ts[to_addr] = ts;
                last_ts[to_addr] = ts;
            }
            counts[to_addr] += 1;
            totals[to_addr] += amt;
            if ts and (not first_ts[to_addr] or ts < first_ts[to_addr]) {
                first_ts[to_addr] = ts;
            }
            if ts and ts > last_ts[to_addr] {
                last_ts[to_addr] = ts;
            }
        }

        for to_addr in counts {
            target = self.addr_to_node[to_addr];
            here +>:Transfer(
                amount=totals[to_addr],
                timestamp=last_ts[to_addr],
                token="ETH",
                tx_count=counts[to_addr],
                total_amount=totals[to_addr],
                first_ts=first_ts[to_addr],
                last_ts=last_ts[to_addr]
            ):+> target;
            self.edges_created += 1;
        }
        visit [-->];
    }
}

walker EnrichFeatures {
    """Compute temporal/behavioral entropy features on each Wallet node —
    signals a GBDT with mean+std timing can't see. Delegates the math to
    compute_entropy_features in Python and stores the result on the node."""
    has tx_by_addr: dict[str, list] = {},
        visited: set = set();

    can start with entry {
        visit [-->];
    }

    can enrich with Wallet entry {
        if here.address in self.visited {
            disengage;
        }
        self.visited.add(here.address);
        txs = self.tx_by_addr.get(here.address, []);
        feats = compute_entropy_features(txs, here.protocol_interactions);
        here.hour_entropy = feats["hour_entropy"];
        here.dow_entropy = feats["dow_entropy"];
        here.burst_score = feats["burst_score"];
        here.ngram_entropy = feats["ngram_entropy"];
        visit [-->];
    }
}

walker SybilProximity {
    """Single-source hop-decayed label propagation along Transfer edges.
    Spawned from a known-sybil seed; deposits `decay^hop` influence on each
    wallet reachable within max_hops (both directions — sybil clusters move
    money bidirectionally). Frontier-based BFS, dedups within a single run."""
    has max_hops: int = 2,
        decay: float = 0.5,
        visited: set = set(),
        frontier: list = [],
        current_hop: int = 0;

    can propagate with Wallet entry {
        self.visited.add(here.address);
        self.frontier = [here];
        while self.current_hop < self.max_hops {
            self.current_hop += 1;
            influence: float = self.decay ** self.current_hop;
            next_frontier: list = [];
            for cur in self.frontier {
                for nbr in [cur ->:Transfer:->] {
                    if nbr.address not in self.visited {
                        self.visited.add(nbr.address);
                        nbr.sybil_proximity += influence;
                        next_frontier.append(nbr);
                    }
                }
                for nbr in [cur <-:Transfer:<-] {
                    if nbr.address not in self.visited {
                        self.visited.add(nbr.address);
                        nbr.sybil_proximity += influence;
                        next_frontier.append(nbr);
                    }
                }
            }
            self.frontier = next_frontier;
        }
    }
}

# ---- Entry Point ----

with entry {
    cache_path = get_cache_path();
    with open(cache_path, "r") as f {
        cache = json.load(f);
    }

    # Load all addresses with on-chain activity
    all_addrs = list(cache.keys());
    addresses = [];
    for addr in all_addrs {
        txs = cache[addr].get("transactions", {}).get("result", []);
        if isinstance(txs, list) and len(txs) > 0 {
            addresses.append(addr);
        }
    }

    print(f"[1/3] Collecting on-chain data from {len(addresses)} addresses...");
    flat_root = Cluster();
    root ++> flat_root;
    for addr in addresses {
        flat_root ++> Wallet(address=addr);
    }
    collector = flat_root spawn DataCollector();
    all_wallet_data = collector.wallet_data;

    # Materialize Transfer edges between tracked wallets (graph-native substrate
    # for downstream walkers: SybilProximity, CounterpartyOverlap, etc.)
    tx_by_addr: dict = {};
    for addr in addresses {
        entry_obj = cache.get(addr, {});
        txs_raw = entry_obj.get("transactions", {}).get("result", []);
        if isinstance(txs_raw, list) {
            tx_by_addr[addr] = txs_raw;
        }
    }
    indexer = GraphBuilder(tx_by_addr=tx_by_addr, phase="index");
    flat_root spawn indexer;
    connector = GraphBuilder(
        tx_by_addr=tx_by_addr,
        addr_to_node=indexer.addr_to_node,
        phase="connect"
    );
    flat_root spawn connector;
    print(f"      Built {connector.edges_created} Transfer edges across {len(indexer.addr_to_node)} wallets");

    # Entropy features (hour/dow/burst/ngram) stored on each Wallet node
    enricher = EnrichFeatures(tx_by_addr=tx_by_addr);
    flat_root spawn enricher;
    print(f"      Enriched {len(enricher.visited)} wallets with entropy features");

    # k-hop label propagation from known-sybil seeds — each wallet accumulates
    # a hop-decayed proximity score to the sybil seed set.
    seed_labels: set = set();
    seed_labels.add("sybil");
    seed_labels.add("sybil_overlap");
    seeds_spawned: int = 0;
    for addr in indexer.addr_to_node {
        seed_node = indexer.addr_to_node[addr];
        if seed_node.label in seed_labels {
            seed_node spawn SybilProximity(max_hops=2, decay=0.5);
            seeds_spawned += 1;
        }
    }
    # Summary of proximity scores
    prox_nonzero: int = 0;
    prox_max: float = 0.0;
    for addr in indexer.addr_to_node {
        n = indexer.addr_to_node[addr];
        if n.sybil_proximity > 0.0 {
            prox_nonzero += 1;
        }
        if n.sybil_proximity > prox_max {
            prox_max = n.sybil_proximity;
        }
    }
    print(f"      Propagated from {seeds_spawned} seeds -> {prox_nonzero} wallets got proximity>0 (max={prox_max})");

    # Snapshot computed node fields by address; cluster-local Wallet nodes
    # (created below in the per-cluster loop) look up and inherit these.
    proximity_by_addr: dict[str, float] = {};
    hour_by_addr: dict[str, float] = {};
    dow_by_addr: dict[str, float] = {};
    burst_by_addr: dict[str, float] = {};
    ngram_by_addr: dict[str, float] = {};
    for addr in indexer.addr_to_node {
        w = indexer.addr_to_node[addr];
        proximity_by_addr[addr] = w.sybil_proximity;
        hour_by_addr[addr] = w.hour_entropy;
        dow_by_addr[addr] = w.dow_entropy;
        burst_by_addr[addr] = w.burst_score;
        ngram_by_addr[addr] = w.ngram_entropy;
    }

    print("[2/3] Building clusters (funding + Louvain)...");
    funder_clusters = build_funding_clusters(all_wallet_data);
    louvain_clusters = build_louvain_clusters(all_wallet_data);
    louvain_clusters = refine_louvain_clusters(louvain_clusters, all_wallet_data);
    clusters = merge_clusters(funder_clusters, louvain_clusters);
    print(f"      {len(clusters)} clusters found");

    print("[3/3] Classifying with LLM reasoning...");
    all_verdicts: list[dict] = [];
    clusters_processed = 0;
    wallets_skipped = 0;
    MAX_AGENTIC_ROUNDS = 3;  # Iteration cap — prevent infinite expansion

    for i in range(len(clusters)) {
        cluster = clusters[i];
        # Skip trivial clusters
        if cluster["size"] < 2 {
            wallets_skipped += cluster["size"];
            continue;
        }

        clusters_processed += 1;

        # Build lookup of pre-collected wallet data for this cluster
        cluster_addr_set = set(cluster["addresses"]);
        addr_to_data: dict = {};
        for wd in all_wallet_data {
            if wd["address"] in cluster_addr_set {
                addr_to_data[wd["address"]] = wd;
            }
        }
        cluster_wallet_data = list(addr_to_data.values());

        # ---- Compute ALL cluster-level signals ----

        # 1. Chain detection
        chain_result = detect_chain(cluster_wallet_data);

        # 2. Amount anomaly detection
        amount_result = detect_amount_anomaly(cluster_wallet_data);

        # 3. Multi-hop funding tree (from cluster funder)
        tree_result = {"root": cluster["funder"], "path": [], "depth": 0, "fan_out": {}};
        if cluster["funder"] and not cluster["funder"].startswith("louvain") {
            tree_result = build_funding_tree(cluster["funder"], max_depth=3);
        }

        # 4. Common funder
        common = find_common_funder(cluster_wallet_data);

        # 5. TX count fingerprint (bot signature: identical tx counts)
        fingerprint_result = detect_tx_count_fingerprint(cluster_wallet_data);

        cluster_signals = {
            "chain": chain_result,
            "amount_anomaly": amount_result,
            "funding_tree": tree_result,
            "common_funder": common if common else "",
            "cluster_size": len(cluster_wallet_data),
            "tx_fingerprint": fingerprint_result
        };

        # Chain trimming for long chains
        analyze_addrs = cluster["addresses"];
        chain_trimmed = 0;
        if chain_result["is_chain"] and chain_result["chain_height"] > 8 {
            chain_order = chain_result["chain_order"];
            chain_height = chain_result["chain_height"];
            head = chain_order[:3];
            tail = chain_order[-3:];
            seen: set = set();
            analyze_addrs = [];
            for a in head + tail {
                if a not in seen {
                    analyze_addrs.append(a);
                    seen.add(a);
                }
            }
            chain_trimmed = chain_height - len(analyze_addrs);
            print(f"    Trimming chain: analyzing first 3 + last 3, skipping {chain_trimmed} middle nodes");
        }

        # Build sub-graph for this cluster
        cluster_node = Cluster(funder=cluster["funder"], priority=i);
        root ++> cluster_node;
        analyze_set = set(analyze_addrs);
        for addr in analyze_addrs {
            wd = addr_to_data.get(addr, {});
            cluster_node ++> Wallet(
                address=addr,
                created_at=wd.get("created_at", ""),
                tx_count=wd.get("tx_count", 0),
                first_funder=wd.get("first_funder", ""),
                protocol_interactions=wd.get("protocol_interactions", []),
                operation_intervals=wd.get("operation_intervals", []),
                label=wd.get("label", "unknown"),
                sybil_proximity=proximity_by_addr.get(addr.lower(), 0.0),
                hour_entropy=hour_by_addr.get(addr.lower(), 0.0),
                dow_entropy=dow_by_addr.get(addr.lower(), 0.0),
                burst_score=burst_by_addr.get(addr.lower(), 0.0),
                ngram_entropy=ngram_by_addr.get(addr.lower(), 0.0)
            );
        }

        # Collect features via Walker
        analyze_wallet_data = [wd for wd in cluster_wallet_data if wd["address"] in analyze_set];
        judge = SybilJudge(wallet_data=all_wallet_data, cluster_data=analyze_wallet_data);
        cluster_node spawn judge;

        # ---- JAC-native classification via by llm() (PRIMARY) ----
        # JAC's structured type-driven LLM reasoning — no manual prompt/JSON parsing
        print("    Classifying with JAC by llm() (primary)...");
        batch_verdicts = [];
        try {
            wallet_features = [];
            for f in judge.features {
                wallet_features.append(WalletFeatures(
                    address=f["address"],
                    tx_count=f["tx_count"],
                    first_funder=f["first_funder"],
                    avg_timing_gap_seconds=f["avg_timing_gap_seconds"],
                    timing_std_seconds=f["timing_std_seconds"],
                    num_protocols=f["num_protocols"],
                    has_common_funder=f["has_common_funder"],
                    behavior_similarity_score=f["behavior_similarity_score"],
                    sybil_proximity=f["sybil_proximity"],
                    hour_entropy=f["hour_entropy"],
                    dow_entropy=f["dow_entropy"],
                    burst_score=f["burst_score"],
                    ngram_entropy=f["ngram_entropy"]
                ));
            }

            # Extract cluster-internal Transfer edges from the flat_root graph:
            # for each analyzed wallet, walk its outgoing Transfer edges and keep
            # only those whose target is also in the analyze set. Gives the LLM
            # the actual sub-graph structure, not just per-wallet features.
            transfer_records: list[TransferRecord] = [];
            analyze_set_lower: set = set();
            for a_addr in analyze_addrs {
                analyze_set_lower.add(a_addr.lower());
            }
            for analyze_addr in analyze_addrs {
                src_node = indexer.addr_to_node.get(analyze_addr.lower(), None);
                if src_node is None {
                    continue;
                }
                for nbr in [src_node ->:Transfer:->] {
                    if nbr.address.lower() not in analyze_set_lower {
                        continue;
                    }
                    for ex in [edge src_node ->:Transfer:-> nbr] {
                        transfer_records.append(TransferRecord(
                            from_addr=src_node.address,
                            to_addr=nbr.address,
                            tx_count=ex.tx_count,
                            total_amount_eth=ex.total_amount,
                            first_ts=ex.first_ts,
                            last_ts=ex.last_ts
                        ));
                    }
                }
            }

            print(f"    Sub-graph: {len(wallet_features)} wallets, {len(transfer_records)} internal transfers");
            jac_verdicts = classify_cluster_jac(
                wallets=wallet_features,
                transfers=transfer_records,
                cluster_size=cluster_signals["cluster_size"] as int,
                common_funder=cluster_signals.get("common_funder", "") as str,
                chain_detected=chain_result.get("is_chain", False),
                chain_height=chain_result.get("chain_height", 0),
                amount_anomaly=amount_result.get("is_anomaly", False),
                dominant_amount=amount_result.get("dominant_amount", 0.0),
                tx_fingerprint=fingerprint_result.get("is_fingerprint", False),
                dominant_tx_count=fingerprint_result.get("dominant_count", 0),
                funding_tree_depth=tree_result.get("depth", 0) as int
            );

            # Convert SybilVerdict objects to dicts for pipeline compatibility
            for v in jac_verdicts {
                batch_verdicts.append({
                    "risk": str(v.risk).replace("SybilRisk.", ""),
                    "confidence": v.confidence,
                    "evidence": v.evidence if v.evidence else [],
                    "reasoning": v.reasoning
                });
            }
            print(f"    [JAC by llm()] classified {len(batch_verdicts)} wallets");
        } except Exception as e {
            print(f"    [JAC by llm() FAILED] falling back to Python: {e}");
            batch_verdicts = llm_classify_cluster_enriched(judge.features, cluster_signals);
        }

        # Post-LLM override: catch false negatives
        batch_verdicts = post_llm_override(batch_verdicts, judge.features, cluster_signals);

        for idx in range(len(judge.features)) {
            v = batch_verdicts[idx];
            judge.verdicts.append({
                "address": judge.features[idx]["address"],
                "risk": v["risk"],
                "confidence": v["confidence"],
                "evidence": v["evidence"],
                "reasoning": v["reasoning"],
                "ground_truth": judge.labels[idx],
                "sybil_proximity": judge.features[idx]["sybil_proximity"],
                "hour_entropy": judge.features[idx]["hour_entropy"],
                "dow_entropy": judge.features[idx]["dow_entropy"],
                "burst_score": judge.features[idx]["burst_score"],
                "ngram_entropy": judge.features[idx]["ngram_entropy"]
            });
            print(f"    {judge.features[idx]['address'][:12]}... => {v['risk']} (conf: {v['confidence']}) [actual: {judge.labels[idx]}]");
        }

        # ---- AGENTIC LOOP: LLM picks investigation tools dynamically ----
        low_conf_count = 0;
        for v in judge.verdicts {
            if v["confidence"] < 0.7 and v["risk"] != "CLEAN" {
                low_conf_count += 1;
            }
        }

        if low_conf_count > 0 {
            print(f"    [Agentic] {low_conf_count} low-conf wallets — LLM-driven tool selection begins");
            evidence_collected: list[str] = [];
            actions_taken: list[str] = [];
            useful_signal_count = 0;
            budget = MAX_AGENTIC_ROUNDS;

            while budget > 0 {
                action_name = "FINALIZE";
                rationale = "";
                try {
                    choice = pick_next_action(
                        low_confidence_count=low_conf_count,
                        cluster_size=cluster_signals["cluster_size"] as int,
                        evidence_collected=evidence_collected,
                        actions_already_taken=actions_taken,
                        budget_remaining=budget
                    );
                    action_name = str(choice.action).replace("InvestigationAction.", "");
                    rationale = choice.rationale;
                    print(f"      [Action {MAX_AGENTIC_ROUNDS - budget + 1}/{MAX_AGENTIC_ROUNDS}] LLM chose: {action_name} — {rationale}");
                } except Exception as e {
                    print(f"      [Action selection failed: {e}] stopping agentic loop");
                    break;
                }

                if action_name == "FINALIZE" {
                    print("      LLM decided evidence is sufficient — finalizing");
                    break;
                }

                new_ev = "";
                has_signal = False;
                if action_name == "EXPAND_FUNDER_TREE" {
                    seed_addr = cluster["funder"] if (cluster["funder"] and not cluster["funder"].startswith("louvain")) else judge.verdicts[0]["address"];
                    deeper_tree = build_funding_tree(seed_addr, max_depth=5);
                    prior_depth = tree_result.get("depth", 0);
                    has_signal = deeper_tree["depth"] > prior_depth;
                    new_ev = f"Deeper funding tree: reached depth={deeper_tree['depth']} (was {prior_depth}), fan_out_keys={len(deeper_tree.get('fan_out', {}))}";
                } else {
                    if action_name == "FIND_SIBLINGS" {
                        sibs = find_sibling_clusters(cluster["funder"], cluster["addresses"], clusters, i);
                        has_signal = sibs['count'] > 0;
                        new_ev = f"Sibling clusters: {sibs['count']} found, {sibs['shares_funder_count']} share funder, {sibs['total_sibling_wallets']} total wallets in wider network";
                    } else {
                        if action_name == "CHECK_TEMPORAL_COHORT" {
                            coh = check_temporal_cohort(cluster_wallet_data);
                            has_signal = coh['wallet_count'] >= 2;
                            new_ev = f"Temporal cohort: {coh['wallet_count']} wallets span {coh['span_hours']}h (cohort_detected={coh['cohort_detected']})";
                        } else {
                            if action_name == "COMPARE_LEGIT_BASELINE" {
                                base = compare_legit_baseline(judge.features);
                                has_signal = len(base['flags']) > 0;
                                new_ev = f"Baseline deviation score={base['suspicion_score']}, flags={base['flags']}";
                            }
                        }
                    }
                }

                signal_marker = "[signal]" if has_signal else "[null]";
                print(f"        -> {signal_marker} {new_ev}");
                evidence_collected.append(new_ev);
                actions_taken.append(action_name);
                if has_signal {
                    useful_signal_count += 1;
                }
                budget -= 1;
            }

            # ---- Reflection: re-issue verdicts with all collected evidence ----
            # Short-circuit: if all tools returned null signals, skip reflection to
            # avoid LLM hallucinating verdict drift based on non-informative evidence.
            if useful_signal_count == 0 and len(evidence_collected) > 0 {
                print(f"      [Reflect SKIPPED] All {len(evidence_collected)} tool(s) returned null signals — keeping prior verdicts");
            }
            if useful_signal_count > 0 {
                print(f"      [Reflect] Updating verdicts with {useful_signal_count} signal-bearing evidence piece(s)...");
                try {
                    reflected = reflect_on_evidence(
                        wallets=wallet_features,
                        new_evidence=evidence_collected
                    );
                    for idx in range(len(reflected)) {
                        if idx < len(judge.verdicts) {
                            old_risk = judge.verdicts[idx]["risk"];
                            old_conf = judge.verdicts[idx]["confidence"];
                            new_risk = str(reflected[idx].risk).replace("SybilRisk.", "");
                            judge.verdicts[idx]["risk"] = new_risk;
                            judge.verdicts[idx]["confidence"] = reflected[idx].confidence;
                            if reflected[idx].evidence {
                                judge.verdicts[idx]["evidence"] = reflected[idx].evidence;
                            }
                            if reflected[idx].reasoning {
                                judge.verdicts[idx]["reasoning"] = reflected[idx].reasoning;
                            }
                            print(f"        {judge.verdicts[idx]['address'][:12]}... {old_risk}({old_conf}) -> {new_risk}({reflected[idx].confidence})");
                        }
                    }
                } except Exception as e {
                    print(f"      [Reflection failed: {e}]");
                }
            }
        }

        all_verdicts += judge.verdicts;
        wallets_skipped += chain_trimmed;

        # Early stopping: if this cluster is all CLEAN, skip remaining
        sybil_in_cluster = 0;
        for v in judge.verdicts {
            if v["risk"] != "CLEAN" {
                sybil_in_cluster += 1;
            }
        }

        if len(judge.verdicts) > 0 and sybil_in_cluster == 0 {
            remaining = 0;
            for j in range(i + 1, len(clusters)) {
                remaining += clusters[j]["size"];
            }
            if remaining > 0 {
                print(f"    Cluster is CLEAN — skipping {len(clusters) - i - 1} remaining cluster(s) ({remaining} wallets)");
                wallets_skipped = remaining;
            }
            break;
        }

        print(f"    Flagged {sybil_in_cluster}/{len(judge.verdicts)} as sybil — continuing to next cluster...");
    }

    # ---- Summary ----
    print("\n=== Summary ===");
    print(f"Clusters processed: {clusters_processed}/{len(clusters)}");
    print(f"Wallets classified: {len(all_verdicts)}");
    if wallets_skipped > 0 {
        print(f"Wallets skipped (early stop): {wallets_skipped}");
    }

    sybil_count = 0;
    for v in all_verdicts {
        if v["risk"] != "CLEAN" {
            sybil_count += 1;
        }
    }
    print(f"Flagged as Sybil: {sybil_count}/{len(all_verdicts)}");

    for v in all_verdicts {
        print(f"\n{v['address']}");
        print(f"  AI Risk:      {v['risk']}");
        print(f"  Confidence:   {v['confidence']}");
        print(f"  Ground Truth: {v['ground_truth']}");
        if len(v["evidence"]) > 0 {
            print("  Evidence:");
            for e in list(v["evidence"]) {
                print(f"    - {e}");
            }
        }
        if v["reasoning"] {
            print(f"  Reasoning:    {v['reasoning']}");
        }
    }

    common = find_common_funder(all_wallet_data);
    if common {
        print(f"\nCommon funder detected across cluster: {common}");
    }

    # Collect all Transfer edges from the flat_root graph for frontend rendering
    # (so the UI can show wallet<->wallet flows, not just funder->wallet spokes).
    classified_set: set = set();
    for v in all_verdicts {
        classified_set.add(v["address"].lower());
    }
    transfer_edges_out: list[dict] = [];
    for addr in indexer.addr_to_node {
        src = indexer.addr_to_node[addr];
        for nbr in [src ->:Transfer:->] {
            src_lower = src.address.lower();
            tgt_lower = nbr.address.lower();
            if src_lower not in classified_set and tgt_lower not in classified_set {
                continue;
            }
            for ex in [edge src ->:Transfer:-> nbr] {
                transfer_edges_out.append({
                    "source": src.address,
                    "target": nbr.address,
                    "tx_count": ex.tx_count,
                    "total_amount": ex.total_amount,
                    "first_ts": ex.first_ts,
                    "last_ts": ex.last_ts
                });
            }
        }
    }
    print(f"Transfer edges for frontend: {len(transfer_edges_out)}");

    # ---- Build JSON output for frontend (delegated to Python) ----
    import os;
    output_path = os.environ.get("SYBILSCOPE_OUTPUT", "../analysis_output.json");
    build_json_output(all_verdicts, all_wallet_data, clusters, sybil_count, common if common else "", output_path, transfer_edges_out);

    print("\nDone!");
}
