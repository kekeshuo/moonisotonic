# References and source boundaries

## Algorithm/behavior references

- SciPy `scipy.optimize.isotonic_regression`: weighted least-squares chain PAVA and returned block interpretation. https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.isotonic_regression.html
- scikit-learn `IsotonicRegression`: empirical monotone model, duplicate coordinates and out-of-bounds behavior as a comparison reference. https://scikit-learn.org/stable/modules/generated/sklearn.isotonic.IsotonicRegression.html

These are behavioral references, not code sources. MoonIsotonic is independently written in MoonBit; no SciPy BSD-3-Clause or scikit-learn BSD-3-Clause implementation has been incorporated. No upstream binary dependency is required. We do not claim parity with their complete APIs or perform a measured speed comparison.

## Runtime dependency

Only bundled `moonbitlang/core` (debug/JSON and prelude collections), distributed with the tested MoonBit toolchain. Core source and license: https://github.com/moonbitlang/core (Apache-2.0).

## Ecosystem comparisons

See `docs/competition/duplicate-check.md` for specific examined modules and API-level boundaries. Those projects were inspected for duplication assessment only, not copied, vendored or made runtime dependencies.
