Can you add a test module for the `WhatCanICook` walker in `cookbook.jac`? Call it `cookbook_tests.jac`.

Quick summary of what it's supposed to do: given a pantry list, it goes over every recipe and works out whether it's cookable — required ingredients must be in the pantry or have a direct substitute that is (optional ones don't matter), it picks the alphabetically-first available substitute, records swaps like `"butter->margarine"`, and reports the cookable recipes sorted by title. I want the tests to nail all of that down. The cookbook code is fine as-is; only add the test file.
