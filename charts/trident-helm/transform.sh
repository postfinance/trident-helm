#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "::group::Generating Trident manifests"
echo "Generating custom Trident YAML manifests using tridentctl..."
echo "Using tridentctl version: $(tridentctl version --client)"
tridentctl install --generate-custom-yaml --silence-autosupport -n dummy
echo "::endgroup::"

echo "::group::Processing manifests"
echo "Cleaning up whitespace and formatting issues..."
for file in setup/*; do
  yq -i '.' "$file"
done

echo "Removing namespace metadata to allow installation in any namespace..."
for file in setup/*; do
  if yq '.metadata |  has("namespace")' "$file" | grep -q true; then
    yq -i 'del(.metadata.namespace)' "$file"
  fi
done
rm setup/trident-namespace.yaml

echo "Injecting Helm templating into manifests..."

# daemonset

image_trident_main=$(yq '(.spec.template.spec.containers[] | select(.name == "trident-main")).image' setup/trident-daemonset.yaml)
image_driver_registrar=$(yq '(.spec.template.spec.containers[] | select(.name == "driver-registrar")).image' setup/trident-daemonset.yaml)

## ressources
yq -i '
  (.spec.template.spec.containers[] | select(.name == "trident-main")).resources = "{{ with .Values.daemonset.tridentMain.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "driver-registrar")).resources = "{{ with .Values.daemonset.driverRegistrar.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
' setup/trident-daemonset.yaml

## images
yq -i "
  (.spec.template.spec.containers[] | select(.name == \"trident-main\")).image = \"{{ with .Values.daemonset.tridentMain.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_trident_main{{ end }}\"
  |
  (.spec.template.spec.containers[] | select(.name == \"driver-registrar\")).image = \"{{ with .Values.daemonset.driverRegistrar.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_driver_registrar{{ end }}\"
" setup/trident-daemonset.yaml


# append tolerations to existing ones in daemonset using sed
sed -i '/tolerations:/a\{{- with .Values.daemonset.tolerations }}{{ toYaml . | nindent 8 }}{{- end }}' setup/trident-daemonset.yaml

# deployment
image_trident_main=$(yq '(.spec.template.spec.containers[] | select(.name == "trident-main")).image' setup/trident-deployment.yaml)
image_trident_autosupport=$(yq '(.spec.template.spec.containers[] | select(.name == "trident-autosupport")).image' setup/trident-deployment.yaml)
image_csi_provisioner=$(yq '(.spec.template.spec.containers[] | select(.name == "csi-provisioner")).image' setup/trident-deployment.yaml)
image_csi_attacher=$(yq '(.spec.template.spec.containers[] | select(.name == "csi-attacher")).image' setup/trident-deployment.yaml)
image_csi_resizer=$(yq '(.spec.template.spec.containers[] | select(.name == "csi-resizer")).image' setup/trident-deployment.yaml)
image_csi_snapshotter=$(yq '(.spec.template.spec.containers[] | select(.name == "csi-snapshotter")).image' setup/trident-deployment.yaml)

yq -i '
  (.spec.template.spec.containers[] | select(.name == "trident-main")).resources = "{{ with .Values.controller.tridentMain.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "trident-autosupport")).resources = "{{ with .Values.controller.tridentAutosupport.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-provisioner")).resources = "{{ with .Values.controller.csiProvisioner.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-attacher")).resources = "{{ with .Values.controller.csiAttacher.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-resizer")).resources = "{{ with .Values.controller.csiResizer.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-snapshotter")).resources = "{{ with .Values.controller.csiSnapshotter.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  .spec.template.spec.tolerations = "{{ with .Values.controller.tolerations }}{{ toYaml . | nindent 8 }}{{ else }}[]{{ end }}"
  |
  .spec.template.metadata.annotations = "{{- if .Values.controller.annotations }}{{ toYaml .Values.controller.annotations | nindent 8 }}{{- end }}"
' setup/trident-deployment.yaml
## resources
yq -i '
  (.spec.template.spec.containers[] | select(.name == "trident-main")).resources = "{{ with .Values.controller.tridentMain.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "trident-autosupport")).resources = "{{ with .Values.controller.tridentAutosupport.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-provisioner")).resources = "{{ with .Values.controller.csiProvisioner.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-attacher")).resources = "{{ with .Values.controller.csiAttacher.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-resizer")).resources = "{{ with .Values.controller.csiResizer.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-snapshotter")).resources = "{{ with .Values.controller.csiSnapshotter.resources }}{{ toYaml . | nindent 12 }}{{ else }}{}{{ end }}"
  |
  .spec.template.spec.tolerations = "{{ with .Values.controller.tolerations }}{{ toYaml . | nindent 8 }}{{ else }}[]{{ end }}"
  |
  .spec.template.metadata.annotations = "{{- if .Values.controller.annotations }}{{ toYaml .Values.controller.annotations | nindent 8 }}{{- end }}"
' setup/trident-deployment.yaml
## images
yq -i "
  (.spec.template.spec.containers[] | select(.name == \"trident-main\")).image = \"{{ with .Values.controller.tridentMain.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_trident_main{{ end }}\"
  |
  (.spec.template.spec.containers[] | select(.name == \"trident-autosupport\")).image = \"{{ with .Values.controller.tridentAutosupport.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_trident_autosupport{{ end }}\"
  |
  (.spec.template.spec.containers[] | select(.name == \"csi-provisioner\")).image = \"{{ with .Values.controller.csiProvisioner.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_csi_provisioner{{ end }}\"
  |
  (.spec.template.spec.containers[] | select(.name == \"csi-attacher\")).image = \"{{ with .Values.controller.csiAttacher.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_csi_attacher{{ end }}\"
  |
  (.spec.template.spec.containers[] | select(.name == \"csi-resizer\")).image = \"{{ with .Values.controller.csiResizer.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_csi_resizer{{ end }}\"
  |
  (.spec.template.spec.containers[] | select(.name == \"csi-snapshotter\")).image = \"{{ with .Values.controller.csiSnapshotter.image }}{{ toYaml . | nindent 12 }}{{ else }}$image_csi_snapshotter{{ end }}\"
" setup/trident-deployment.yaml

echo "Fixing quotes around Helm templating..."
sed -i "s/'{{/{{/g; s/}}'/}}/g" setup/*
echo "::endgroup::"

echo "::group::Organizing Helm chart"
echo "Moving CRDs to crds/ folder..."
mkdir -p crds/
mv -f setup/trident-crds.yaml crds/

echo "Moving templates to templates/ folder..."
mv -f setup/* templates/
rm -rf setup/
echo "::endgroup::"

echo "::group::Validating Helm chart"
echo "Rendering Helm chart to verify template syntax..."
helm template .
echo "✅ Helm chart validation successful"
echo "::endgroup::"

echo "🎉 Trident Helm chart transformation completed successfully!"
