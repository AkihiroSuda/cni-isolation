# CNI Bridge Isolation Plugin (`/opt/cni/bin/isolation`)

The `isolation` plugin isolates CNI bridge networks as in Docker bridge networks.

This plugin is mostly expected to be used by the following projects:
- containerd ([nerdctl](https://github.com/AkihiroSuda/nerdctl))
- BuildKit
- [Podman](https://github.com/containers/podman/issues/5805)

This plugin is being proposed to be merged into the CNI upstream `firewall` plugin: https://github.com/containernetworking/plugins/pull/584

## Install

```bash
make && sudo make install
```

The binary is installed as `/opt/cni/bin/isolation` .

## Configuration

`{"type":"isolation"}` needs to be inserted AFTER `{"type":"bridge"}`.

When `{"type":"firewall"}` is also present, `{"type":"isolation"}` needs to be inserted AFTER `{"type":"firewall"}`.

Example:

```json
{
   "cniVersion": "0.4.0",
   "name": "foo1",
   "plugins": [
      {
         "type": "bridge",
         "bridge": "cni1",
         "isGateway": true,
         "ipMasq": true,
         "hairpinMode": true,
         "ipam": {
            "type": "host-local",
            "routes": [
               {
                  "dst": "0.0.0.0/0"
               }
            ],
            "ranges": [
               [
                  {
                     "subnet": "10.88.3.0/24",
                     "gateway": "10.88.3.1"
                  }
               ]
            ]
         }
      },
      {
         "type": "firewall"
      },
      {
         "type": "isolation"
      }
   ]
}
```

## How it works

The `isolation` plugin follows the behavior of Docker libnetwork (`DOCKER-ISOLATION-STAGE-1` and `DOCKER-ISOLATION-STAGE-2`).

To isolate CNI bridges (`cni1`, `cni2`, ...), the `isolation` plugin executes the following `iptables` commands.

```bash
iptables -N CNI-ISOLATION-STAGE-1
iptables -N CNI-ISOLATION-STAGE-2
# NOTE: "-j CNI-ISOLATION-STAGE-1" needs to be before "CNI-FORWARD" created by CNI firewall plugin. So we use -I here.
iptables -I FORWARD -j CNI-ISOLATION-STAGE-1
iptables -A CNI-ISOLATION-STAGE-1 -i cni1 ! -o cni1 -j CNI-ISOLATION-STAGE-2
iptables -A CNI-ISOLATION-STAGE-1 -i cni2 ! -o cni2 -j CNI-ISOLATION-STAGE-2
iptables -A CNI-ISOLATION-STAGE-1 -j RETURN
iptables -A CNI-ISOLATION-STAGE-2 -o cni1 -j DROP
iptables -A CNI-ISOLATION-STAGE-2 -o cni2 -j DROP
iptables -A CNI-ISOLATION-STAGE-2 -j RETURN
```

The number of commands is O(N) where N is the number of the bridges (not the number of the containers).

Run `sudo iptables-save -t filter` to confirm the added rules.

## FAQs
### Is this plugin made for Kubernetes?

No, this plugin is mostly made for single-node CNI projects, including, but not limited to, containerd, BuildKit, and Podman.

### Why `isolation` needs to be specified after `firewall` ?

When `isolation` is specified before `firewall`, the `isolation` rules are discarded, because 
`firewall` plugin inserts a `FORWARD` rule that jumps to `CNI-FORWARD` chain before our `CNI-ISOLATION-STAGE-1` chain.

We will be able to relax this order constraint after adding `isolation` plugin to the CNI upstream.

### iptables rules are not removed after deletion of all containers

The iptables rules are created per bridge, not per container.
So the iptables rules remain even after deletion of all containers.

To remove iptables rules created by `isolation` plugin, use [`hack/show-commands-to-delete-isolation-rules.sh`](./hack/show-commands-to-delete-isolation-rules.sh).
