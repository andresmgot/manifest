local kube = import "kube.libsonnet";

local host = "kubeless-ui";

{
  namespace:: {metadata+: {namespace: "kubeless"}},

  serviceAccount: kube.ServiceAccount("kubeless-ui") + $.namespace,

  editorRole: kube.ClusterRole("kubeless-editor") {
    rules: [
      {
        apiGroups: ["k8s.io"],
        resources: ["functions"],
        verbs: ["get", "list", "watch", "create", "patch"],
      },
    ],
  },

  editorBinding: kube.ClusterRoleBinding("kubeless-ui-editor") {
    roleRef_: $.editorRole,
    subjects_: [$.serviceAccount],
  },

  svc: kube.Service("kubeless-ui") + $.namespace {
    target_pod: $.deploy.spec.template,
  },

  deploy: kube.Deployment("kubeless-ui") + $.namespace {
    spec+: {
      template+: {
        spec+: {
          serviceAccountName: $.serviceAccount.metadata.name,
          containers_+: {
            default: kube.Container("ui") {
              // FIXME: point to real tag
              image: "bitnami/kubeless-ui:latest",
              ports_: {
                ui: {containerPort: 3000, protocol: "TCP"},
              },
              readinessProbe: {
                httpGet: {path: "/", port: 3000},
              },
            },
            proxy: kube.Container("proxy") {
              image: "kelseyhightower/kubectl:1.4.0",
              args: ["proxy", "-p", "8080"],
            },
          },
        },
      },
    },
  },
}
