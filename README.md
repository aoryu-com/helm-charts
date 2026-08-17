# helm-charts
Repo for modified helm charts

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
