# This file provides templated metric specifications that enable
# Iter8 to retrieve metrics from Istio's Prometheus add-on.
# 
# For a list of metrics supported out-of-the-box by the Istio Prom add-on, 
# please see https://istio.io/latest/docs/reference/config/metrics/
#
# Iter8 substitutes the placeholders in this file with values, 
# and uses the resulting metric specs to query Prometheus.
# The placeholders are as follows.
# 
# reporter                        string  optional
# destinationWorkload             string  required
# destinationWorkloadNamespace    string  required
# elapsedTimeSeconds              int     implicit
# startingTime                    string  optional
# latencyPercentiles              []int   optional
#
# For descriptions of reporter, destinationWorkload, and destinationWorkloadNamespace, 
# please see https://istio.io/latest/docs/reference/config/metrics/
#
# elapsedTimeSeconds: this should not be specified directly by the user. 
# It is implicitly computed by Iter8 according to the following formula
# elapsedTimeSeconds := (time.Now() - startingTime).Seconds()
# 
# startingTime: By default, this is the time at which the Iter8 experiment started.
# The user can explicitly specify the startingTime for each app version
# (for example, the user can set the startingTime to the creation time of the app version)
#
# latencyPercentiles: Each item in this slice will create a new metric spec.
# For example, if this is set to [50,75,90,95],
# then, latency-p50, latency-p75, latency-p90, latency-p95 metric specs are created.

{{- define "istio-prom-reporter"}}
{{- if .reporter }}
reporter="{{ .reporter }}",
{{- end }}
{{- end }}

{{- define "istio-prom-dest"}}
{{ template "istio-prom-reporter" . }}
handler="{{ .handler }}",
endpoint="{{ .endpoint }}"
{{- end }}

# url is the HTTP endpoint where the Prometheus service installed by Istio's Prom add-on
# can be queried for metrics

url: "http://prometheus-k8s.monitoring/api/v1/query"
provider: istio-prom
method: GET
metrics:
- name: request-count
  type: counter
  description: |
    Number of requests
  params:
  - name: query
    value: |
      sum(prometheus_http_requests_total{
        {{ template "istio-prom-dest" . }}
      }) or on() vector(0)
  jqExpression: .data.result[0].value[1] | tonumber
- name: error-count
  type: counter
  description: |
    Number of unsuccessful requests
  params:
  - name: query
    value: |
      sum(prometheus_http_requests_total{
        {{ template "istio-prom-dest" . }}
      }) or on() vector(0) - sum(prometheus_http_requests_total{
        {{ template "istio-prom-dest" . }}
      }) or on() vector(0)
  jqExpression: .data.result[0].value[1] | tonumber
- name: error-rate
  type: gauge
  description: |
    Fraction of unsuccessful requests
  params:
  - name: query
    value: |
      ((sum(prometheus_http_requests_total{
        {{ template "istio-prom-dest" . }}
      }) or on() vector(0)) - (sum(prometheus_http_requests_total{
        {{ template "istio-prom-dest" . }}
      }) or on() vector(0)))/(sum(prometheus_http_requests_total{
        {{ template "istio-prom-dest" . }}
      }) or on() vector(0))
  jqExpression: .data.result.[0].value.[1]
