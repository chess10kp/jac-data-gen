I need a tiny hit-counter API for my static blog. This folder is a `jac create --kind service` project. Replace the sample with:

- one public walker endpoint `record_visit` (so it's `POST /walker/record_visit`) taking `page: str`
- each call bumps that page's counter (one node per page under root; counts must survive across requests) and reports `{"page": <page>, "visits": <count after this visit>}`
- a blank page name (empty or only spaces) shouldn't be counted — report `{"error": "page required"}` instead
- page names are trimmed, otherwise case-sensitive (`/About` and `/about` are different pages)

Please also add a couple of Jac tests for it and make sure `jac start` serves it.
