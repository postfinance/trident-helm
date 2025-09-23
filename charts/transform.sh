#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Generating custom Trident YAML manifests..."
tridentctl install --generate-custom-yaml --silence-autosupport -n dummy

# this needs to be done because on one CRD there are leading whitespaces which helm template chokes on
echo "Fixing leading whitespace issues in CRD manifest..."
yq setup/trident-crds.yaml > setup/trident-crds.yaml

# linting fails
echo "Removing empty lines from manifests..."
sed -i '/^[[:space:]]*$/d' setup/*

# remove namespace metadata to allow installation in any namespace
echo "Removing namespace metadata from manifests..."
for file in setup/*; do
  if yq '.metadata |  has("namespace")' "$file" | grep -q true; then
    yq -i 'del(.metadata.namespace)' "$file"
  fi
done

rm setup/trident-namespace.yaml

echo "Injecting Helm templating into manifests..."

# daemonset
yq -i '
  (.spec.template.spec.containers[] | select(.name == "trident-main")).resources = "{{- if .Values.daemonset.tridentMain.resources }}{{ toYaml .Values.daemonset.tridentMain.resources | nindent 12 }}{{- end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "driver-registrar")).resources = "{{- if .Values.daemonset.driverRegistrar.resources }}{{ toYaml .Values.daemonset.driverRegistrar.resources | nindent 12 }}{{- end }}"
' setup/trident-daemonset.yaml

# Insert tolerations Helm templating only if values exist
sed -i '/^[[:space:]]*tolerations:/a\{{- if .Values.daemonset.tolerations }}{{ toYaml .Values.daemonset.tolerations | indent 8 }}{{- end }}' setup/trident-daemonset.yaml

# deployment
yq -i '
  (.spec.template.spec.containers[] | select(.name == "trident-main")).resources = "{{- if .Values.controller.tridentMain.resources }}{{ toYaml .Values.controller.tridentMain.resources | nindent 12 }}{{- end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "trident-autosupport")).resources = "{{- if .Values.controller.tridentAutosupport.resources }}{{ toYaml .Values.controller.tridentAutosupport.resources | nindent 12 }}{{- end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-provisioner")).resources = "{{- if .Values.controller.csiProvisioner.resources }}{{ toYaml .Values.controller.csiProvisioner.resources | nindent 12 }}{{- end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-attacher")).resources = "{{- if .Values.controller.csiAttacher.resources }}{{ toYaml .Values.controller.csiAttacher.resources | nindent 12 }}{{- end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-resizer")).resources = "{{- if .Values.controller.csiResizer.resources }}{{ toYaml .Values.controller.csiResizer.resources | nindent 12 }}{{- end }}"
  |
  (.spec.template.spec.containers[] | select(.name == "csi-snapshotter")).resources = "{{- if .Values.controller.csiSnapshotter.resources }}{{ toYaml .Values.controller.csiSnapshotter.resources | nindent 12 }}{{- end }}"
  |
  .spec.template.spec.tolerations = "{{- if .Values.controller.tolerations }}{{ toYaml .Values.controller.tolerations | nindent 8 }}{{- end }}"
  |
  .spec.template.metadata.annotations = "{{- if .Values.controller.annotations }}{{ toYaml .Values.controller.annotations | nindent 8 }}{{- end }}"
' setup/trident-deployment.yaml


# Fix single quotes around Helm templating added by yq
sed -i "s/'{{/{{/g; s/}}'/}}/g" setup/*

echo "Moving generated manifests from setup/ to templates/ for Helm usage..."
mv -f setup/* templates/
rm -rf setup/

echo "Rendering the Helm chart to verify output..."
helm template .

echo "Done! The Helm chart has been prepared and rendered."