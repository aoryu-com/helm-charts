# waha

A Helm chart for deploying [WAHA](https://waha.devlike.pro) (WhatsApp HTTP API) on Kubernetes.

## Important: WAHA is stateful

One running pod holds one live WhatsApp session lock. **Do not** scale `replicaCount` above `1` —
the chart refuses to render if you try. To run multiple WhatsApp numbers, install this chart
multiple times with different `nameOverride`/`fullnameOverride` and separate
`session.existingClaim` values.

The Deployment also uses the `Recreate` strategy, not `RollingUpdate`, so a new pod never briefly
contends with the old one for the session lock during an update.

## Installing

Secrets are not defaulted — you must set them explicitly on install (or supply
`secret.existingSecret`), otherwise the chart fails to render:

```sh
helm install my-waha oci://ghcr.io/<owner>/charts/waha \
  --set secret.apiKey=$(uuidgen | tr -d '-') \
  --set secret.dashboardPassword=$(uuidgen | tr -d '-') \
  --set secret.swaggerPassword=$(uuidgen | tr -d '-')
```

Or point at credentials you manage out-of-band (Vault, External Secrets Operator, SealedSecrets):

```sh
helm install my-waha oci://ghcr.io/<owner>/charts/waha \
  --set secret.existingSecret=my-waha-credentials
```

The expected keys in either case: `WAHA_API_KEY`, `WAHA_DASHBOARD_USERNAME`,
`WAHA_DASHBOARD_PASSWORD`, `WHATSAPP_SWAGGER_USERNAME`, `WHATSAPP_SWAGGER_PASSWORD`.

## Usage

Once the pod is running, WAHA exposes a REST API and dashboard on the Service port (`3000` by
default). Every API call other than the health check needs the `X-Api-Key` header, set to
whatever you gave `secret.apiKey`.

Reach it via your Ingress host, or port-forward for local testing:

```sh
kubectl port-forward svc/my-waha 3000:3000
```

**1. Confirm it's up:**

```sh
curl http://localhost:3000/api/server/status
```

**2. Start a session and get the QR code** to link a WhatsApp number (this is the "one session
per pod" lock mentioned above — one running session is what this chart is built for):

```sh
curl -X POST http://localhost:3000/api/sessions/start \
  -H "X-Api-Key: <secret.apiKey>" \
  -H "Content-Type: application/json" \
  -d '{"name": "default"}'

curl http://localhost:3000/api/default/auth/qr \
  -H "X-Api-Key: <secret.apiKey>" \
  --output qr.png
```

Scan `qr.png` from WhatsApp on your phone (Linked Devices). Once linked, the session data is
written to the `session` PVC, so a pod restart won't require re-scanning.

**3. Send a message:**

```sh
curl -X POST http://localhost:3000/api/sendText \
  -H "X-Api-Key: <secret.apiKey>" \
  -H "Content-Type: application/json" \
  -d '{"session": "default", "chatId": "1234567890@c.us", "text": "hello from WAHA"}'
```

**Dashboard:** `http://<host>/dashboard`, Basic Auth via `secret.dashboardUsername` /
`secret.dashboardPassword`.

**Interactive API docs (Swagger):** protected by Basic Auth via `secret.swaggerUsername` /
`secret.swaggerPassword` — check WAHA's own docs for the exact path on your image version.

The full API surface (webhooks, media, groups, multi-device, etc.) is documented at
[waha.devlike.pro/docs](https://waha.devlike.pro/docs).

## Values

| Key | Description | Default |
|---|---|---|
| `replicaCount` | Must stay `1` — see above | `1` |
| `image.repository` | `devlikeapro/waha` for Core, `devlikeapro/waha-plus` with a Plus license, or the `:arm` variants on ARM nodes | `devlikeapro/waha` |
| `image.tag` | Pin in production, e.g. `"2026.1.10"`. Empty uses `appVersion`/`latest` | `""` |
| `imagePullSecrets` | Only needed for the private `waha-plus` image | `[]` |
| `service.type` / `service.port` | Service exposing the WAHA API/dashboard | `ClusterIP` / `3000` |
| `ingress.enabled` | Expose via Ingress | `false` |
| `ingress.host` | Public hostname; should match `env.WAHA_BASE_URL` | `waha.example.com` |
| `ingress.tls.enabled` | Terminate TLS at the Ingress | `false` |
| `env` | Non-secret WAHA config, mapped 1:1 onto [documented env vars](https://waha.devlike.pro/docs/how-to/config) | see `values.yaml` |
| `extraEnv` | Additional plain env vars as a list of `{name, value}` | `[]` |
| `secret.existingSecret` | Reuse a pre-provisioned Secret instead of letting the chart create one | `""` |
| `secret.apiKey` / `secret.dashboardPassword` / `secret.swaggerPassword` | Required when `existingSecret` is unset; no defaults on purpose | `""` |
| `session.enabled` | Persist WhatsApp session/auth data (Chrome profile / NOWEB store) | `true` |
| `session.existingClaim` | Reuse a pre-provisioned PVC instead of creating one | `""` |
| `session.size` | PVC size | `5Gi` |
| `dshm.enabled` | Mount a memory-backed `emptyDir` at `/dev/shm` for the WEBJS (headless Chrome) engine | `true` |
| `dshm.sizeLimit` | Size of that `/dev/shm` mount | `1Gi` |
| `resources` | WAHA's own docs list 2 CPU / 2GB RAM as a floor for one active session | see `values.yaml` |
| `probes` | Liveness/readiness against WAHA's health endpoint | see `values.yaml` |

See `values.yaml` for the full set of configurable values, including `nodeSelector`, `tolerations`,
`affinity`, and `serviceAccount`.

## Notes

- Losing the `session` PVC means every WhatsApp session has to re-scan its QR code.
- `WAHA_BASE_URL` should match your public Ingress URL so callback/media links resolve correctly.
