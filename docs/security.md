# Input and deployment boundaries

The library makes no network calls, opens no files, accesses no environment variables and reads no credentials. JSON/TSV operate on caller-provided text; callers own ingestion and storage security.

Reject nonfinite observations, nonpositive weights, empty or mismatched series, malformed models, overlapping holdout rows, bad fold assignments and unsupported schemas. Arithmetic overflow is an error, not a usable calibrated model. Do not treat error text as a stable machine-readable taxonomy.

JSON and TSV text budgets are 16000000 string units, TSV defaults to 100000 rows, reliability bins at most 10000, cross-validation at most 1000 folds. Resampling limits are 200 plans, 10000 queries and 1000000 total row entries. See entrypoint code for exact validation order and overrides. JSON uses the core parser's default nesting limit (not a custom depth-8 policy).

Array training entrypoints have no global row-count cap. Sorting, allocations and repeated quantile block sorting can still consume significant resources. Apply stricter caller quotas, timeouts and process isolation before accepting adversarial input. Native/WebAssembly execution is not itself a resource-budget guarantee.

Public structs are mutable through their array fields. Validate untrusted constructed values; use `copy_model` for independently retained model arrays. Some composite workflow results are intended as returned trusted objects, not an authenticated interchange format. Only the JSON model codec is designed as a serialized input boundary.

Probability evaluation cannot prove causal validity, calibration under distribution shift, or absence of data leakage. This software is not medical/financial decision advice. Report holdout and binning choices when using it in consequential applications.

To report defects use the repository issues, supplying minimal synthetic inputs and the exact module/toolchain version. Never include credentials or private raw observations.
