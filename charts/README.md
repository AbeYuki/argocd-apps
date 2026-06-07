# Helm Charts

## リポジトリ追加

```
helm repo add abeyuki-charts \
    https://abeyuki.github.io/argocd-apps/charts/
```
```
helm repo update
```

## charts リスト

```
helm search repo abeyuki-charts
```

## Instart chart

```
helm upgrade --install <release-name> \
    abeyuki-charts/<chart-name> \
    --namespace <namespace> \ 
    --create-namespace \
    -f values.yaml
```

## Uninstall

```
helm uninstall <release-name> --namespace <namespace>
```

## Helm リポジトリのインデックス


# 運用

### Actions

- chars/ に変更があると Helm チャートのパッケージと index を pages に公開(workflow: helm-pages)
- tagpr は chart のみを対象に PR と タグを作成(workflwo: tagpr)

### PR
- chart の変更は charts の内容だけの PR にする
