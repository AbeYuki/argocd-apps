## Actions Overview

- charts/** に変更があると、HelmチャートのパッケージとindexをGitHub Pagesへ公開（Workflow: helm-pages）。
- charts/** に触れるPRでChartのversionを自動更新（Workflow: chart-version-bump）。
- tagprはchartsのみを対象にリリースPRとタグを作成（Workflow: tagpr）。

## Chart Versioning (chart-version-bump)

- PRラベルでbumpを決定: tagpr:major / tagpr:minor、無ければpatch。
- 変更されたchartのChart.yaml versionを自動更新。
- Chart.yamlのappVersionは手動で更新。

## tagpr Operation (per chart)

- mainでcharts/**に変更があるときのみ実行。
- chartごとの設定はcharts/<name>/.tagprを使用。
- タグはcharts/<name>/vX.Y.Zで、chartごとに独立してバージョン管理。
- CHANGELOGはcharts/<name>/CHANGELOG.mdに出力。

## Recommended PR Practice

- chartの変更はcharts/**だけを触るPRに分ける。
- manifests/など他の変更は別PRにして、リリースログをきれいに保つ。
