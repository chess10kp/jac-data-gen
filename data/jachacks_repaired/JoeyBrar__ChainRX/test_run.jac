"""Quick CLI test for ChainRX chain detection."""

import from main { run_analysis, get_all_drugs }

with entry {
    print("=== ChainRX Drug Interaction Chain Detector ===\n");
    print(f"Available drugs: {get_all_drugs()}\n");

    # Test 1: Triple Whammy
    print("--- Test 1: Triple Whammy (Ibuprofen + Lisinopril + Metformin) ---");
    results = run_analysis(["Ibuprofen", "Lisinopril", "Metformin"]);
    for r in results {
        print(f"  {r['explanation']}");
        for m in r["mechanisms"] {
            print(f"    - {m}");
        }
    }
    print(f"Total flagged chains: {len(results)}\n");

    # Test 2: Serotonin Syndrome
    print("--- Test 2: Serotonin Syndrome (Sertraline + Tramadol + Ondansetron) ---");
    results = run_analysis(["Sertraline", "Tramadol", "Ondansetron"]);
    for r in results {
        print(f"  {r['explanation']}");
    }
    print(f"Total flagged chains: {len(results)}\n");

    # Test 3: Bleeding Risk
    print("--- Test 3: Bleeding Risk (Warfarin + Aspirin + Ibuprofen) ---");
    results = run_analysis(["Warfarin", "Aspirin", "Ibuprofen"]);
    for r in results {
        print(f"  {r['explanation']}");
    }
    print(f"Total flagged chains: {len(results)}\n");

    # Test 4: No interactions
    print("--- Test 4: Safe combo (Metformin + Amiodarone) ---");
    results = run_analysis(["Metformin", "Amiodarone"]);
    for r in results {
        print(f"  {r['explanation']}");
    }
    print(f"Total flagged chains: {len(results)}\n");
}
