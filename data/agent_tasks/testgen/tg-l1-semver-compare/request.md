I need tests for the version comparison logic in `semver.jac` — specifically `compare` (and the `cmp_pre` pre-release rules it relies on) plus `max_satisfying` for caret ranges. Parsing and bumping are already covered elsewhere so you can skip them.

Put the tests in `semver_compare_tests.jac`. Pre-release precedence is the part people always get wrong (numeric vs alphanumeric identifiers, shorter vs longer, release > pre-release), so be thorough there. Don't edit `semver.jac`.
