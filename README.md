# Research Publications Affiliated with Luxembourg: A Data-Driven Analysis

A reproducible analysis that:

1. Fetches and analyses metadata from the [OpenAlex API](https://openalex.org).
2. Performs bibliometric and statistical analysis using R. The analysis is executed in a reproducible environment defined with Nix.
3. The analysis is compiled through GitHub Actions and the report published on GitHub Pages.

---

## Usage

1. Reade the analysis [here]().

2. To reproduce locally, first install Nix. [Follow these instructions](https://docs.determinate.systems/).

3. Bootstrap the execution environment by installing R and `{rix}` in a temporary Nix shell:

   ```bash
   nix-shell -p R rPackages.rix
   ```

4. Start R, and source the `gen-env.R` script:

   ```r
   source("gen-env.R")
   ```

5. Leave R and the temporary shell, then build the enviroment:

   ```bash
   nix-build
   ```

6. Drop into the enviroment and source the `gen-pipeline.R` script:

   ```r
   source("gen-pipeline.R")
   ```

7. Check out the output by running:

   ```r
   rixpress::rxp_copy("report")
   ```

   You'll find the report in `pipeline-output/report.html`


## Licenses

### Code

The source code in this repository is licensed under the **European Union Public Licence v1.2 (EUPL‑1.2)**.

- Strong copyleft: if you modify and distribute the code, you must retain the same license or a compatible one.
- SPDX identifier in each file: `SPDX-License-Identifier: EUPL-1.2`

See [`LICENSE`](./LICENSE) and [`LICENSES/EUPL-1.2.txt`](./LICENSES/EUPL-1.2.txt) for details.

### Report

The report (`report/` directory) is licensed under the **Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)**
license.

- You may share and adapt the work non-commercially, as long as you give credit and license your derivatives under the same terms.
- SPDX identifier in each file: `SPDX-License-Identifier: CC-BY-NC-SA-4.0`

See [`paper/LICENSE`](./paper/LICENSE) and [`LICENSES/CC-BY-NC-SA-4.0.txt`](./LICENSES/CC-BY-NC-SA-4.0.txt) for details.


## REUSE Compliance

This repository follows the [REUSE Specification](https://reuse.software/):

- All source files include SPDX license headers.
- Full license texts are located in the `LICENSES/` directory.
- Licensing metadata is described in `REUSE.toml`.

You can check compliance with:

```bash
reuse lint
```

## Acknowledgments

- [OpenAlex](https://openalex.org): Open scholarly metadata API
- [Quarto](https://quarto.org): Scientific and technical publishing
- [Typst](https://typst.app): Modern typesetting engine
- [Nix](https://nixos.org/): Reproducible development environments
- [rix](https://docs.ropensci.org/rix/): Use Nix for R easily
- [rixpress](https://b-rodrigues.github.io/rixpress/): Define reproducible pipelines with R
