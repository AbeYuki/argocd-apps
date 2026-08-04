# Longhorn PVC の XFS から ext4 への移行

既存 PVC のデータを維持した再フォーマット不可
ext4 の新規 PVC の作成とコピー元 PVC のデータ移行

## 移行手順

1. コピー元ボリュームの Longhorn バックアップまたはスナップショットの作成
2. コピー元 PVC をマウントしているすべての Pod の停止
   データベースの場合はアプリケーションの手順に従った安全な停止
3. `xfs-to-ext4.yaml` の namespace とコピー元／コピー先 PVC 名と要求容量の変更
   コピー先にはコピー元の容量以上を設定
4. manifest の適用と移行 Job の完了待機

   ```sh
   kubectl apply -f manifests/longhorn-migration/xfs-to-ext4.yaml
   kubectl wait --for=condition=complete --timeout=24h \
     job/migrate-pvc-xfs-to-ext4 -n default
   kubectl logs -n default job/migrate-pvc-xfs-to-ext4
   ```

5. ワークロードによる `destination-pvc-ext4` の使用設定と起動
   アプリケーションデータの確認
6. アプリケーションの動作確認完了まで古い PVC を保持
   不要になった Job の削除
   ロールバック可能期間の終了後に古い PVC を削除

`longhorn-ha` に `fsType: ext4` を設定済み
Job によるコピー前の両ファイルシステムの確認
コピー先が空でない場合の処理中止
`cp -a` によるファイル属性の維持と `diff -qr` によるコピー結果の比較

StatefulSet の `volumeClaimTemplate` から作成された PVC は既存 StatefulSet での名前変更不可
コピー先 PVC を参照する新しい StatefulSet の作成または対象アプリケーションの復元手順の利用
