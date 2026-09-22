"""
  fromId
    toId
      commodId=traderow
    toId
      commodId=traderow
  fromId
    toId
      commodId=traderow
    toId
      commodId=traderow
  """
def ProfitArrayToHierarchy(oneway: list[dict[str, str]], prune: dict | None = None) -> dict {
    if prune is None {
        prune = {};
    }
    for way in oneway {
        if way["AbaseId"] == way["BbaseId"] {
            continue;
        }
        if way["AbaseId"] not in prune {
            prune[way["AbaseId"]] = {};
        }
        if way["BbaseId"] not in prune[way["AbaseId"]] {
            prune[way["AbaseId"]][way["BbaseId"]] = {};
        }
        if way["commodityId"] not in prune[way["AbaseId"]][way["BbaseId"]] {
            prune[way["AbaseId"]][way["BbaseId"]][way["commodityId"]] = way;
        }
    }
    return prune;
}