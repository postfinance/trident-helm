# trident-cli-helm

This is a Helm chart deploys the controller and daemonset for trident CSI based on the manifests output by `tridentctl`.

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter                                   | Description                                 | Default   |
|----------------------------------------------|---------------------------------------------|-----------|
| `daemonset.tridentMain.resources`            | Resource requests/limits for trident-main   | `{}`      |
| `daemonset.driverRegistrar.resources`        | Resource requests/limits for driver-registrar | `{}`    |
| `daemonset.tolerations`                      | Tolerations for DaemonSet pods              | `[]`      |
| `controller.annotations`                     | Annotations for controller pods             | `{}`      |
| `controller.tridentMain.resources`           | Resource requests/limits for controller trident-main | `{}` |
| `controller.tridentAutosupport.resources`    | Resource requests/limits for trident-autosupport | `{}` |
| `controller.csiProvisioner.resources`        | Resource requests/limits for csi-provisioner | `{}`    |
| `controller.csiAttacher.resources`           | Resource requests/limits for csi-attacher   | `{}`      |
| `controller.csiResizer.resources`            | Resource requests/limits for csi-resizer    | `{}`      |
| `controller.csiSnapshotter.resources`        | Resource requests/limits for csi-snapshotter | `{}`    |
| `controller.tolerations`                     | Tolerations for controller pods             | `[]`      |

## Contributing

Feel free to submit issues and pull requests for improvements or bug fixes.

### Upgrading Chart

1. Download tridentctl version you'd like to update to
2. Run `transform.sh`
