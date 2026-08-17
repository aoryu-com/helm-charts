# Helm Charts
This is a repo for helm chart

## Publishing to GHCR (OCI)

Charts live under `charts/<name>/`. Tagging `<name>-v<Chart.yaml version>` (e.g. `myapp-v1.2.3`) on `main`
triggers `.github/workflows/publish-chart.yml`, which packages and pushes the chart to
`oci://ghcr.io/<owner>/charts/<name>`.

The tag's version must match `version` in the chart's `Chart.yaml`, or the workflow fails.

Install directly from GHCR:

```sh
helm install <release> oci://ghcr.io/<owner>/charts/<name> --version <version>
```

No manual `helm registry login` is needed to pull public charts. Publishing requires the
default `GITHUB_TOKEN` (already granted `packages: write` in the workflow) — nothing to
configure by hand as long as the repo's package visibility settings allow it.


### AI Declaration 
This repo makes use of ai `Claude Code (Sonnet 5)` to help ease the burden on the maintainer (me) :P, there is no way I can write out so many 
templates in such a short time, but rest assured all values and template are validated. Only automation is generated
by ai to help me bring a regularly updated chart :), Please dont hate on me.