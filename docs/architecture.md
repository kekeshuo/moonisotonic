# Architecture and numerical contracts

## Layers

1. `validation`, `pava`, `order`: finite observations/positive weights, stack of disjoint contiguous blocks, half-open block expansion, least-squares optimality diagnostics.
2. `quantile`, `bounds`: canonical lower weighted block quantiles and closed bounded block means. A violating neighboring block pair is pooled; infeasible interval chains fail before fitting.
3. `prepare`, `model*`, `predict`, `inverse`, `codec`: stable coordinate ordering with original row identities, duplicate-coordinate grouping, strictly increasing knots with direction-consistent values, portable validation and prediction.
4. `table`, `evaluate`, `reliability`, `holdout`, `cross_validation`, `explain`, `band`, `resample`: explicit workflows rather than hidden randomness or training-state mutation.

No package initialization performs I/O. Public functions return `Result[..., String]` for invalid inputs; example unwraps are for fixed valid fixtures only. Array copies are made when independence is required; publicly mutable model arrays are revalidated at use boundaries.

## Important distinctions

L2 duplicate-coordinate groups can be compressed to weighted means. L1/quantile groups retain every original y/weight; taking the quantile of group means would solve the wrong objective. Nonunique quantile minimizers use the lower empirical endpoint deterministically, including decreasing fits. Band bounds are separately fitted with the same canonical convention and checked for crossing.

Weights must be positive and finite; their sum and reported losses must remain finite. Stable convex combinations reduce avoidable intermediate overflow, but no guarantee is made over all finite IEEE inputs or extreme dynamic ranges. Projection residual diagnostics are descriptive checks, not a formal floating-point proof.

The JSON wire layout is `["moonisotonic/1", direction, lossName, tau, [[x,y,weight],...]]`; squared/absolute use tau=0. Decode rejects wrong shape/version/ordering/nonfinite numbers and excessive knots. Default max_knots is defined in `codec.mbt` and may be overridden downwards by callers. This is not a pickle format.

Holdout validates nonempty, disjoint, unique original row indices. Cross-validation predicts each row using a model trained without its fold. Duplicate entities and time dependence are the caller's responsibility. Resampling intentionally permits repeated indices and requires explicit plans. Neither empirical band coverage nor resampling sensitivity is a confidence claim.

## Verification design

- `oracle_wbtest.mbt` enumerates all 363 length-1..5 ternary observation sequences with alternating positive weights. For both directions it compares L2 against all contiguous partitions (726 fits), and three quantile levels against all ternary fitted sequences (2178 fits). Order and idempotence are also checked.
- `bounds_oracle_wbtest.mbt` enumerates length-1..3 observations and three interval types, 819 configurations in both directions (1638 fits). An independent all-partitions clipped-mean solver compares objective values and infeasible outcomes.
- `contracts_test.mbt` consumes only public APIs: mutation isolation, malformed workflows, affine/weight transformation, duplicate-coordinate quantile semantics.
- Feature tests cover the remaining model/table/evaluation/inverse/partition APIs. Three main packages check end-to-end scenarios without target-specific I/O.

These finite oracles are reproducible evidence, not a proof for arbitrary data or a benchmark. The exhaustive quantile oracle is intentionally restricted to observations for which an optimum can be represented on the enumerated levels.

## Compatibility

The source is target-independent. CI uses wasm-gc, wasm, js and native, with strict warnings, a build, tests and each example. Local native execution requires a C compiler; CI on Ubuntu supplies one. Generated public interface changes must be intentional; CI regenerates interfaces and rejects tracked differences after formatting.
