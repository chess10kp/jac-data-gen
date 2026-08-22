  1. Get the source data (do first — unblocks everything)
  Download nuprl/MultiPL-T from HuggingFace and inspect its schema — confirm each record carries the Python function and its test cases (the paper
  says it does; verify the exact field names). This decides step 2's difficulty.

  2. Resolve the one real unknown: test translation
  This is the piece I did not verify. I diff-tested with hand-written Jac assertions. You need to turn MultiPL-T's Python test cases into runnable
  Jac ones at scale. Quickest experiment: take one real MultiPL-T record, concatenate function + its assert cases into one .py, run jac tool
  py2jac, and see if the asserts transpile into valid test blocks. If yes, the whole pipeline is mechanical. If no, you need a small
  assertion-formatter. Prove or disprove this on 3–5 real examples before building anything.

  3. Pick and prompt the idiomize model
  Decide which LLM writes idiomatic Jac and how you feed it Jac idiom (the jac guide reference, examples, style rules). py2jac output is your floor
  — the agent has to beat mechanical Python-in-Jac-syntax to be worth the compute.

  4. Then build the batch harness
  Loop over records: py2jac → idiomize → jac test → keep-or-fallback. Log the idiomatic-kept vs. fell-back ratio — that's your headline quality
  metric. Finish with jac fmt + ROUGE-L dedup.

  Recommended order: 1 → 2 first. Step 2 is the fork in the road — it's either a non-issue or a small tool to write, and you can't scope the
  harness until you know which. Want me to run step 2 now on a real MultiPL-T record?
