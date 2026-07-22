# home-lab

My HomeLab — k3s single-node cluster, GitOps via Flux.

## Architecture

```mermaid
flowchart TD
    subgraph gh["GitHub: go-nick/home-lab"]
        repo[("git repo (main)")]
    end

    subgraph flux["flux-system namespace"]
        gr["GitRepository/flux-system poll 1m"]
        kroot["Kustomization/flux-system ./clusters/staging interval 10m"]
        kapps["Kustomization/apps ./apps/staging · interval 1m"]
    end

    subgraph ld["linkding namespace"]
        lddep["Deployment/linkding"]
        ldpvc["PVC (storage.yaml) ⚠ not wired into kustomization.yaml yet!"]
    end

    subgraph ml["mealie namespace"]
        mldep["Deployment ealie mountPath: /app/data"]
        mlsvc["Service (LoadBalancer)"]
        mlpvc["PVC mealie-pv StorageClass: local-path"]
    end

    node[["node hostPath /var/lib/rancher/k3s/storage/"]]

    repo -- ssh clone --> gr
    gr -- artifact tarball --> kroot
    kroot -- applies clusters/staging/apps.yaml --> kapps
    kapps -- kustomize build apps/staging/linkding --> ld
    kapps -- kustomize build apps/staging/mealie --> ml
    mlpvc -. local-path-provisioner .-> node
    ldpvc -. local-path-provisioner .-> node
```

**Reconcile chain:** `GitRepository` (fetch-only, no cluster writes) → root `Kustomization` (bootstraps Flux itself + applies everything under `clusters/staging`, including `apps.yaml`) → `apps` `Kustomization` (builds `apps/staging/*` overlays, applies to their namespaces).

**Known issue:** `apps/base/linkding/kustomization.yaml` doesn't list `storage.yaml` in `resources` — PVC not actually applied yet.
