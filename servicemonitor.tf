resource "kubectl_manifest" "servicemonitor_crd" {
  yaml_body = <<-YAML
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: servicemonitors.monitoring.coreos.com
spec:
  group: monitoring.coreos.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              selector:
                type: object
              endpoints:
                type: array
                items:
                  type: object
                  properties:
                    port:
                      type: string
                    interval:
                      type: string
                    path:
                      type: string
          status:
            type: object
  scope: Namespaced
  names:
    plural: servicemonitors
    singular: servicemonitor
    kind: ServiceMonitor
YAML
}