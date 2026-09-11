"""TalonT-Org/AutoSkillit#3951 — planner post-compile BEM integration (pre-lift)."""

from collections import deque


def build_dep_adjacency(issues: list[dict]) -> dict[str, list[str]]:
  # plan_id -> depends-on plan_ids (hand-rolled adjacency)
  nodes = [row["plan_id"] for row in issues]
  adj = {n: [] for n in nodes}
  for row in issues:
    pid = row["plan_id"]
    for dep in row.get("depends_on", []):
      if dep in adj:
        adj[pid].append(dep)
  return adj


def build_successor_adjacency(dep_adj: dict[str, list[str]]) -> dict[str, list[str]]:
  succ: dict[str, list[str]] = {n: [] for n in dep_adj}
  for node, deps in dep_adj.items():
    for dep in deps:
      succ[dep].append(node)
  for node in succ:
    succ[node] = sorted(succ[node])
  return succ


def kahn_parallel_groups(dep_adj: dict[str, list[str]]) -> list[list[str]]:
  # BFS wave grouping: each deque drain is one dispatch group
  in_deg = {n: len(deps) for n, deps in dep_adj.items()}
  succ_adj = build_successor_adjacency(dep_adj)
  ready: deque[str] = deque(sorted(n for n, d in in_deg.items() if d == 0))
  parent_wave: dict[str, int] = {}
  groups: list[list[str]] = []
  wave_no = 0
  while ready:
    wave_no += 1
    wave: list[str] = []
    for _ in range(len(ready)):
      node = ready.popleft()
      parent_wave[node] = wave_no
      wave.append(node)
      for nxt in succ_adj[node]:
        in_deg[nxt] -= 1
        if in_deg[nxt] == 0:
          ready.append(nxt)
    groups.append(sorted(wave))
  return groups


def flatten_merge_order(groups: list[list[str]]) -> list[str]:
  order: list[str] = []
  for group in groups:
    order.extend(group)
  return order


def load_bem_groups(execution_map: dict) -> list[list[str]]:
  raw = execution_map.get("groups", [])
  return [sorted(g) for g in raw]


def infer_group_types(groups: list[list[str]]) -> list[str]:
  return ["parallel" if len(g) > 1 else "sequential" for g in groups]


def assign_dispatch_labels(merge_order: list[str]) -> dict[str, str]:
  return {pid: f"D-{idx:02d}" for idx, pid in enumerate(merge_order, start=1)}


def rename_issue_title(plan_id: str, title: str, dispatch_label: str) -> str:
  return f"[{dispatch_label}] {plan_id}: {title}"


def _peer_order_in_group(plan_id: str, group: list[str], merge_order: list[str]) -> list[str]:
  peers = [p for p in merge_order if p in group]
  return peers


def format_execution_context(
  plan_id: str,
  groups: list[list[str]],
  merge_order: list[str],
  group_types: list[str],
  plan_to_issue: dict[str, int],
  plan_to_title: dict[str, str],
  deferred: list[str] | None = None,
) -> str:
  group = next(g for g in groups if plan_id in g)
  group_idx = groups.index(group) + 1
  gtype = group_types[group_idx - 1]
  position = merge_order.index(plan_id) + 1
  total_positions = len(merge_order)
  peers = sorted(p for p in group if p != plan_id)
  peers_txt = ", ".join(peers) if peers else "None"
  idx = merge_order.index(plan_id)
  if idx == 0 or plan_id == _peer_order_in_group(plan_id, group, merge_order)[0]:
    pred_line = "None — first in group"
  else:
    prev = merge_order[idx - 1]
    pred_line = f"#{plan_to_issue[prev]} {plan_to_title[prev]}"
  if idx == len(merge_order) - 1:
    succ_line = "None — last in sequence"
  else:
    nxt = merge_order[idx + 1]
    succ_line = f"#{plan_to_issue[nxt]} {plan_to_title[nxt]}"
  gated = ", ".join(sorted(deferred or [])) or "None"
  return (
    "## Execution Context\n"
    f"- **Dispatch group**: Group {group_idx} of {len(groups)}\n"
    f"- **Group type**: {gtype}\n"
    f"- **Dispatch position**: Position {position} of {total_positions}\n"
    f"- **Immediate predecessor**: {pred_line}\n"
    f"- **Immediate successor**: {succ_line}\n"
    f"- **Group peers**: {peers_txt}\n"
    f"- **Gated by**: {gated}\n"
  )
