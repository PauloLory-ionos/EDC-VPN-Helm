# edc-vpn

Deploys the SIMPL EDC connector with the VPN extension. The VPN Service is not part of this chart:
it is deployed with its own chart (vpn-service repo), and `vpn.apiUrl` points the connector at it.

## Install

```bash
helm install provider charts/edc-vpn -f provider-values.yaml
```

`provider-values.yaml`, the minimum:

```yaml
image:
  repository: <registry>.cr.de-fra.ionos.com/edc-vpn-demo/connector
  tag: "0.0.1"
imagePullSecrets:
  - name: ionos-cr
participantId: provider
vpn:
  apiUrl: http://<vpn-service>:8080/vpnApi/v1
```

The pull Secret for a private registry:

```bash
kubectl create secret docker-registry ionos-cr --docker-server=<registry> \
  --docker-username=<token name> --docker-password=<token>
```

The consumer is another release with its own values (`participantId: consumer`, ...).

## Values

| Value | Default | |
| --- | --- | --- |
| `image.repository`, `image.tag` | `""`, `0.0.1` | the connector image (required) |
| `participantId` | `provider` | `edc.participant.id` |
| `dspCallbackAddress` | this release's Service | `edc.dsp.callback.address` |
| `ports.*`, `paths.*` | 8181–8383, `/api`… | the connector's web contexts |
| `apiKey.value` | `""` | Management API key (`edc.api.auth.key`) set directly |
| `apiKey.secretName` | `""` | Secret with the Management API key; wins over `apiKey.value` |
| `infrastructure.provisioningApiUrl` | `http://simplurl/api/v1/simpl` | `edc.infrastructure.simpl.provisioning.api.url` |
| `infrastructure.defaultAuthToken.secretName` | `""` | Secret with `edc.infrastructure.simpl.default.auth.token` |
| `vpn.apiUrl` | `""` | the VPN Service's local API; the extension is off while empty |
| `vpn.callbackUrl` | this release's Service, control port | where the VPN Service posts tunnel events |
| `vpn.pollIntervalSeconds` | `10` | how often the extension polls the tunnel's state |
| `extraConfig` | `{}` | other settings, written as-is into `config.properties` |
| `extraContainers`, `extraVolumes` | `[]` | added to the Pod as they are |
| `service.expose` | default, management, protocol, control, public | ports on the Service |
| `networkPolicy.enabled` | `false` | ingress only to the exposed ports |

## Where the VPN Service runs

The extension sends the data to the counterpart's VPN IP, so the connector's traffic has to leave
through the VPN Service's `wg0`: the two must share a network namespace, i.e. a Pod. With the VPN
Service in a Pod of its own, the tunnel opens but the data does not go through it.

To run it as a sidecar of this Pod, add its container with `extraContainers` / `extraVolumes` (the
vpn-service chart's named templates give its env, ports and volumes), then point the connector at
the loopback:

```yaml
vpn:
  apiUrl: http://127.0.0.1:8080/vpnApi/v1
  callbackUrl: http://127.0.0.1:8283/control
```

## The connector image

Built from `launchers/dev/vpn-demo/Dockerfile.connector` with the provider launcher, which has every
extension (the consumer launcher is a subset of it):

```bash
./gradlew :launchers:dev:connector-provider:installDist -x javadoc
cd launchers/dev
docker build -f vpn-demo/Dockerfile.connector --build-arg CONNECTOR=connector-provider \
  -t <registry>/edc-vpn-demo/connector:0.0.1 .
docker push <registry>/edc-vpn-demo/connector:0.0.1
```
