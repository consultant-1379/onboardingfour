{{/*
Create chart name and version as used by the chart label.
*/}}{{/*
{{- define "eric-cbrs-dc.chart-OLD" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}*/}}

{{/*
Create image registry url
*/}}{{/*
{{- define "eric-cbrs-dc.registryUrl" -}}
{{- if .Values.global.registry.url -}}
{{- print .Values.global.registry.url -}}
{{- else -}}
{{- print .Values.imageCredentials.registry.url -}}
{{- end -}}
{{- end -}}*/}}

{{/*
Create image pull secrets
*/}}{{/*
{{- define "eric-cbrs-dc.pullSecrets-OLD" -}}
{{- if .Values.global.pullSecret -}}
{{- print .Values.global.pullSecret -}}
{{- else if .Values.imageCredentials.pullSecret -}}
{{- print .Values.imageCredentials.pullSecret -}}
{{- end -}}
{{- end -}}*/}}

{{/*
Generate labels
*/}}
{{- define "eric-cbrs-dc.metadata_app_labels" }}
app: {{ .Values.service.name | quote }}
app.kubernetes.io/name: {{ .Values.service.name | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/version: {{ template "eric-cbrs-dc.chart" . }}
{{- end }}

{{/*
Create replicas
*/}}{{/*
{{- define "eric-cbrs-dc.replicas" -}}
{{- $replica_SG_name := printf "%s-%s" "replicas" .Chart.Name -}}
{{- if index .Values "global" $replica_SG_name -}}
{{- print (index .Values "global" $replica_SG_name) -}}
{{- else if index .Values $replica_SG_name -}}
{{- print (index .Values $replica_SG_name) -}}
{{- end -}}
{{- end -}}*/}}

{{/*
Generate product name
*/}}{{/*
{{- define "eric-cbrs-dc.productName" -}}
{{- $product_name := printf "%s-%s" "helm" .Chart.Name -}}
{{- print $product_name -}}
{{- end -}}*/}}

{{/*
Generate product number
*/}}{{/*
{{- define "eric-cbrs-dc.productNumber" -}}
{{- if .Values.productInfo -}}
{{- print .Values.productInfo.number -}}
{{- end -}}
{{- end -}}*/}}

{{/*
Generate product revision
*/}}{{/*
{{- define "eric-cbrs-dc.productRevision" -}}
{{- if .Values.productInfo -}}
{{- print .Values.productInfo.rstate -}}
{{- end -}}
{{- end -}}*/}}

{{/*
Generate Product info
*/}}{{/*
#product-info for configmap is resides inside _configmap.yaml
#If any change in the below product-info. Its Mandatory to change in the _configmap.yaml
{{- define "eric-cbrs-dc.product-info-OLD" }}
ericsson.com/product-name: {{ default (include "eric-cbrs-dc.productName" .) }}
ericsson.com/product-number: {{ default (include "eric-cbrs-dc.productNumber" .) .Values.productNumber }}
ericsson.com/product-revision: {{ default (include "eric-cbrs-dc.productRevision" .) .Values.productRevision }}
{{- end}}*/}}

{{/*
Generate config map  name
*/}}
{{- define "eric-cbrs-dc.configmapName" -}}
{{- $top := first . -}}
{{- $configmap_name := printf " %s\n" $top  | replace ".yaml" "" -}}
{{ printf $configmap_name }}
{{- end -}}


{{/*
Taken from adp-helm-dr-checker template example
*/}}

{{/* vim: set filetype=mustache: */}}


{{/*
The mainImage Path  (DR-D1121-067)
*/}}
{{- define "eric-cbrs-dc.mainImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.mainImage.registry -}}
    {{- $repoPath := $productInfo.images.mainImage.repoPath -}}
    {{- $name := $productInfo.images.mainImage.name -}}
    {{- $tag := $productInfo.images.mainImage.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.mainImage -}}
            {{- if .Values.imageCredentials.mainImage.registry -}}
                {{- if .Values.imageCredentials.mainImage.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.mainImage.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.mainImage.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.mainImage.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The initImage Path  (DR-D1121-067)
*/}}
{{- define "eric-cbrs-dc.initImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.initImage.registry -}}
    {{- $repoPath := $productInfo.images.initImage.repoPath -}}
    {{- $name := $productInfo.images.initImage.name -}}
    {{- $tag := $productInfo.images.initImage.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.initImage -}}
            {{- if .Values.imageCredentials.initImage.registry -}}
                {{- if .Values.imageCredentials.initImage.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.initImage.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.initImage.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.initImage.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
The monitoringImage Path  (DR-D1121-067)
*/}}
{{- define "eric-cbrs-dc.monitoringImagePath" }}
    {{- $productInfo := fromYaml (.Files.Get "eric-product-info.yaml") -}}
    {{- $registryUrl := $productInfo.images.monitoringImage.registry -}}
    {{- $repoPath := $productInfo.images.monitoringImage.repoPath -}}
    {{- $name := $productInfo.images.monitoringImage.name -}}
    {{- $tag := $productInfo.images.monitoringImage.tag -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.url -}}
                {{- $registryUrl = .Values.global.registry.url -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials -}}
        {{- if .Values.imageCredentials.monitoringImage -}}
            {{- if .Values.imageCredentials.monitoringImage.registry -}}
                {{- if .Values.imageCredentials.monitoringImage.registry.url -}}
                    {{- $registryUrl = .Values.imageCredentials.monitoringImage.registry.url -}}
                {{- end -}}
            {{- end -}}
            {{- if not (kindIs "invalid" .Values.imageCredentials.monitoringImage.repoPath) -}}
                {{- $repoPath = .Values.imageCredentials.monitoringImage.repoPath -}}
            {{- end -}}
        {{- end -}}
        {{- if not (kindIs "invalid" .Values.imageCredentials.repoPath) -}}
            {{- $repoPath = .Values.imageCredentials.repoPath -}}
        {{- end -}}
    {{- end -}}
    {{- if $repoPath -}}
        {{- $repoPath = printf "%s/" $repoPath -}}
    {{- end -}}
    {{- printf "%s/%s%s:%s" $registryUrl $repoPath $name $tag -}}
{{- end -}}

{{/*
Create a map from ".Values.global" with defaults if missing in values file.
This hides defaults from values file.
*/}}
{{ define "eric-cbrs-dc.global" }}
  {{- $globalDefaults := dict "security" (dict "tls" (dict "enabled" true)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "nodeSelector" (dict)) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "registry" (dict "pullSecret" "eric-cbrs-dc-secret")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "externalIPv4" (dict "enabled")) -}}
  {{- $globalDefaults := merge $globalDefaults (dict "externalIPv6" (dict "enabled")) -}}
  {{ if .Values.global }}
    {{- mergeOverwrite $globalDefaults .Values.global | toJson -}}
  {{ else }}
    {{- $globalDefaults | toJson -}}
  {{ end }}
{{ end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eric-cbrs-dc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
External Service name with IPv4 or IPv6 suffix (if enabled).
*/}}
{{- define "eric-cbrs-dc.ext-service.name" -}}

{{- if and (.Values.service.externalService.externalIPv4.enabled | quote) (.Values.service.externalService.externalIPv6.enabled | quote) -}}
{{- fail "Both IPv6 and IPv4 can not be enabled at the same time" }}
{{- end }}

{{- if quote .Values.service.externalService.externalIPv4.enabled -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}-ipv4
{{- else if quote .Values.service.externalService.externalIPv6.enabled -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}-ipv6
{{- else -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}-external
{{- end -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Print the original name of the chart.
*/}}{{/*
{{- define "{{.Chart.Name}}.print" -}}
{{- print .Chart.Name -}}
{{- end -}}*/}}

{{/*
Create chart version as used by the chart label.
*/}}
{{- define "eric-cbrs-dc.version" -}}
{{- printf "%s" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eric-cbrs-dc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create image pull secrets
*/}}
{{- define "eric-cbrs-dc.pullSecrets" -}}
    {{- $globalPullSecret := "" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.pullSecret -}}
            {{- $globalPullSecret = .Values.global.pullSecret -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials.pullSecret -}}
        {{- print .Values.imageCredentials.pullSecret -}}
    {{- else if $globalPullSecret -}}
        {{- print $globalPullSecret -}}
    {{- end -}}
{{- end -}}

{{/*
Create mainImage's registry imagePullPolicy
*/}}
{{- define "eric-cbrs-dc.mainImage.registryImagePullPolicy" -}}
    {{- $globalRegistryPullPolicy := "IfNotPresent" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $globalRegistryPullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials.mainImage.registry -}}
        {{- if .Values.imageCredentials.mainImage.registry.imagePullPolicy -}}
        {{- $globalRegistryPullPolicy = .Values.imageCredentials.mainImage.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
    {{- print $globalRegistryPullPolicy -}}
{{- end -}}

{{/*
Create initImage's registry imagePullPolicy
*/}}
{{- define "eric-cbrs-dc.initImage.registryImagePullPolicy" -}}
    {{- $registryImagePullPolicy := "IfNotPresent" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $registryImagePullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials.initImage.registry -}}
        {{- if .Values.imageCredentials.initImage.registry.imagePullPolicy -}}
        {{- $registryImagePullPolicy = .Values.imageCredentials.initImage.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
    {{- print $registryImagePullPolicy -}}
{{- end -}}

{{/*
Create monitoringImage's registry imagePullPolicy
*/}}
{{- define "eric-cbrs-dc.monitoringImage.registryImagePullPolicy" -}}
    {{- $registryImagePullPolicy := "IfNotPresent" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.registry -}}
            {{- if .Values.global.registry.imagePullPolicy -}}
                {{- $registryImagePullPolicy = .Values.global.registry.imagePullPolicy -}}
            {{- end -}}
        {{- end -}}
    {{- end -}}
    {{- if .Values.imageCredentials.monitoringImage.registry -}}
        {{- if .Values.imageCredentials.monitoringImage.registry.imagePullPolicy -}}
        {{- $registryImagePullPolicy = .Values.imageCredentials.monitoringImage.registry.imagePullPolicy -}}
        {{- end -}}
    {{- end -}}
    {{- print $registryImagePullPolicy -}}
{{- end -}}


{{/*
Create annotation for the product information (DR-D1121-064, DR-D1121-067)
*/}}
{{- define "eric-cbrs-dc.product-info" }}
ericsson.com/product-name: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productName | quote }}
ericsson.com/product-number: {{ (fromYaml (.Files.Get "eric-product-info.yaml")).productNumber | quote }}
ericsson.com/product-revision: {{ regexReplaceAll "(.*)[+|-].*" .Chart.Version "${1}" | quote }}
{{- end}}

{{/*
Create a user defined annotation (DR-D1121-065, DR-D1121-060)
*/}}
{{ define "eric-cbrs-dc.config-annotations" }}
{{- if .Values.annotations -}}
{{- range $name, $config := .Values.annotations }}
{{ $name }}: {{ tpl $config $ }}
{{- end }}
{{- end }}
{{- if .Values.global -}}
{{- if .Values.global.annotations -}}
{{- range $name, $config := .Values.global.annotations }}
{{ $name }}: {{ tpl $config $ }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Create a user defined label (DR-D1121-068, DR-D1121-060)
*/}}
{{ define "eric-cbrs-dc.config-labels" }}
{{- if .Values.labels -}}
{{- range $name, $config := .Values.labels }}
{{ $name }}: {{ tpl $config $ }}
{{- end }}
{{- end }}
{{- if .Values.global -}}
{{- if .Values.global.labels -}}
{{- range $name, $config := .Values.global.labels }}
{{ $name }}: {{ tpl $config $ }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create a merged set of nodeSelectors from global and service level.
*/}}
{{ define "eric-cbrs-dc.nodeSelector" }}
  {{- $g := fromJson (include "eric-cbrs-dc.global" .) -}}
  {{- if .Values.nodeSelector -}}
    {{- range $key, $localValue := .Values.nodeSelector -}}
      {{- if hasKey $g.nodeSelector $key -}}
          {{- $globalValue := index $g.nodeSelector $key -}}
          {{- if ne $globalValue $localValue -}}
            {{- printf "nodeSelector \"%s\" is specified in both global (%s: %s) and service level (%s: %s) with differing values which is not allowed." $key $key $globalValue $key $localValue | fail -}}
          {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- toYaml (merge $g.nodeSelector .Values.nodeSelector) | trim -}}
  {{- else -}}
    {{- toYaml $g.nodeSelector | trim -}}
  {{- end -}}
{{ end }}
{{/*
Create annotations for roleBinding.
*/}}
{{- define "eric-cbrs-dc.securityPolicy.annotations" }}
ericsson.com/security-policy.name: "restricted/default"
ericsson.com/security-policy.privileged: "false"
ericsson.com/security-policy.capabilities: "N/A"
{{- end -}}
{{/*
Create roleBinding reference.
*/}}
{{- define "eric-cbrs-dc.securityPolicy.reference" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.security -}}
            {{- if .Values.global.security.policyReferenceMap -}}
              {{ $mapped := index .Values "global" "security" "policyReferenceMap" "default-restricted-security-policy" }}
              {{- if $mapped -}}
                {{ $mapped }}
              {{- else -}}
                {{ $mapped }}
              {{- end -}}
            {{- else -}}
              default-restricted-security-policy
            {{- end -}}
        {{- else -}}
          default-restricted-security-policy
        {{- end -}}
    {{- else -}}
      default-restricted-security-policy
    {{- end -}}
{{- end -}}
{{/*
Create annotations for cloudProviderLB.
*/}}
{{/*
Create cloudProviderLB annotation for the external service
*/}}
{{- define "eric-cbrs-dc.cloudProviderLB.annotations" }}
{{- if .Values.service.externalService.annotations.cloudProviderLB }}
{{ toYaml .Values.service.externalService.annotations.cloudProviderLB }}
{{- end }}
{{- end}}

{{/*
Create annotation for the external service when IPv4 is enabled
*/}}
{{- define "eric-cbrs-dc.cloudProviderLB.annotations-IPv4" }}
{{- if .Values.service.externalService.externalIPv4.annotations.cloudProviderLB }}
{{ toYaml .Values.service.externalService.externalIPv4.annotations.cloudProviderLB }}
{{- end }}
{{- end}}

{{/*
Create annotation for the external service when IPv6 is enabled
*/}}
{{- define "eric-cbrs-dc.cloudProviderLB.annotations-IPv6" }}
{{- if .Values.service.externalService.externalIPv6.annotations.cloudProviderLB }}
{{ toYaml .Values.service.externalService.externalIPv6.annotations.cloudProviderLB }}
{{- end }}
{{- end}}

##new external ip handling
{{/*
Create IPv4 boolean service/global/<notset>
*/}}
{{- define "eric-cbrs-dc.ext-service.enabled-IPv4" -}}
{{- if .Values.service.externalService.externalIPv4.enabled | quote -}}
{{- .Values.service.externalService.externalIPv4.enabled -}}
{{- else -}}
{{- if .Values.global -}}
{{- if .Values.global.externalIPv4 -}}
{{- if .Values.global.externalIPv4.enabled | quote -}}
{{- .Values.global.externalIPv4.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create IPv6 boolean service/global/<notset>
*/}}
{{- define "eric-cbrs-dc.ext-service.enabled-IPv6" -}}
{{- if .Values.service.externalService.externalIPv6.enabled | quote -}}
{{- .Values.service.externalService.externalIPv6.enabled -}}
{{- else -}}
{{- if .Values.global -}}
{{- if .Values.global.externalIPv6 -}}
{{- if .Values.global.externalIPv6.enabled | quote -}}
{{- .Values.global.externalIPv6.enabled -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the IPv4 service annotations to use
*/}}
{{- define "eric-cbrs-dc.ext-service.annotations-ipv4" -}}
{{- if .Values.service.externalService.externalIPv4.annotations.sharedVIPLabel }}
metallb.universe.tf/allow-shared-ip: {{ .Values.service.externalService.externalIPv4.annotations.sharedVIPLabel }}
{{- end }}
{{- if .Values.service.externalService.externalIPv4.annotations.addressPoolName }}
metallb.universe.tf/address-pool: {{ .Values.service.externalService.externalIPv4.annotations.addressPoolName }}
{{- end }}
{{- end -}}

{{/*
Create the IPv6 service annotations to use
*/}}
{{- define "eric-cbrs-dc.ext-service.annotations-ipv6" -}}
{{- if .Values.service.externalService.externalIPv6.annotations.sharedVIPLabel }}
metallb.universe.tf/allow-shared-ip: {{ .Values.service.externalService.externalIPv6.annotations.sharedVIPLabel }}
{{- end }}
{{- if .Values.service.externalService.externalIPv6.annotations.addressPoolName }}
metallb.universe.tf/address-pool: {{ .Values.service.externalService.externalIPv6.annotations.addressPoolName }}
{{- end }}
{{- end -}}

{{/*
Create the legacy service annotations to use
*/}}
{{- define "eric-cbrs-dc.ext-service.annotations" -}}
{{- if .Values.service.externalService.annotations.sharedVIPLabel }}
metallb.universe.tf/allow-shared-ip: {{ .Values.service.externalService.annotations.sharedVIPLabel }}
{{- end }}
{{- if .Values.service.externalService.annotations.addressPoolName }}
metallb.universe.tf/address-pool: {{ .Values.service.externalService.annotations.addressPoolName }}
{{- end }}
{{- end -}}

{{/*
definition of ports and selector for external service
*/}}
{{- define "eric-cbrs-dc.ext-service.ports" }}
  ports:
  - name: jboss
    protocol: TCP
    port: {{ .Values.service.jbossPort }}
    targetPort: jboss-port
{{- end -}}
{{- define "eric-cbrs-dc.ext-service.selector" }}
  selector:
    app.kubernetes.io/name: {{ template "eric-cbrs-dc.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}