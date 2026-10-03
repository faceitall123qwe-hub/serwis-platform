{{- define "serwis.labels" -}}
app.kubernetes.io/part-of: serwis
app.kubernetes.io/managed-by: argocd
{{- end }}

{{- define "serwis.podSecurity" -}}
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
  runAsGroup: 10001
  fsGroup: 10001
  seccompProfile:
    type: RuntimeDefault
{{- end }}

{{- define "serwis.containerSecurity" -}}
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: [ALL]
{{- end }}

{{- define "serwis.dbEnv" -}}
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: serwis-db-app
      key: uri
{{- end }}
