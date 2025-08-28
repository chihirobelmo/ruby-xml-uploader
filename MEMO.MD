## 保存先

> このリポジトリ内でXMLファイルはどのような名前でどこに保存されていますか

このリポジトリでは、アップロードされたXMLファイルは
storageディレクトリ（例: storage）の下に、Active Storageによって管理されるサブディレクトリ（ハッシュ値のような名前）に保存されます。

ファイル名自体は元のファイル名（例: sample.xml）がActive StorageのDB（active_storage_blobsテーブル）に記録され、
物理ファイルはstorage配下のランダムなキー名（例: 5ngdyyzjfxtc3a30zdmvwpaxrqkv）で保存されます。

つまり、

実ファイル名: ランダムなキー（例: storage/5n/gd/yyzjfxtc3a30zdmvwpaxrqkv など）
元のファイル名: DBで管理（ダウンロード時は元のファイル名で保存される）
保存場所はstorageディレクトリ配下です。

### 結びつき

> DBと実ファイルの結びつきはどのようになっていますか

active Storageでは、DBと実ファイルの結びつきは以下のように管理されています。

1. active_storage_blobsテーブル
実ファイルの「キー」（ランダムな文字列）、元のファイル名、MIMEタイプなどを保存
例: key: "5ngdyyzjfxtc3a30zdmvwpaxrqkv", filename: "sample.xml"
2. active_storage_attachmentsテーブル
モデル（例: XmlDocument）とactive_storage_blobsの関連を保存
どのレコードにどのファイルが添付されているかを管理
3. 実ファイル
storageディレクトリ配下に、active_storage_blobs.keyで保存
例: storage/5n/gd/yyzjfxtc3a30zdmvwpaxrqkv
結びつきの流れ
モデル（XmlDocument）のレコード作成
ファイルアップロード → active_storage_blobsにファイル情報保存
active_storage_attachmentsでモデルとblobを紐付け
実ファイルはstorageディレクトリにkey名で保存
まとめ:
モデル → active_storage_attachments → active_storage_blobs → 実ファイル（storageディレクトリ）
このリレーションでDBと実ファイルが結びついています。

### 将来的なAWSサービスへの保存

> たとえば保存先をAWSのサービスにすることも可能ですか

はい、Active StorageはAWS S3などのクラウドストレージサービスに保存先を変更することが可能です。

主な手順
Gemfileにaws-sdk-s3を追加し、bundle install
storage.ymlにS3用の設定を追加
production.rbなどでconfig.active_storage.service = :amazonを指定
AWSのアクセスキー等を環境変数やcredentials.yml.encで管理
例: storage.yml

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: ap-northeast-1
  bucket: your-bucket-name
```

この設定で、アップロードファイルはS3に保存されます。

### 改善候補

- フラッシュのスタイル整備
- パスワード最小長などの追加バリデーション
- CSRF例外設定のAPI分離が必要ならAPI用のBaseControllerを切り出し

- current_userはセッション → Cookieの順で復元、Cookie一致時はセッション再セット
- CookieのSameSite/secure/httponlyのポリシー調整（本番はsecure: trueを推奨、HTTPS前提）
- rememberトークンの有効期限を短縮したい場合はpermanentではなく一定期間に
- 端末別にrememberを無効化したい場合はrememberトークンを別テーブルで複数持たせる運用に拡張

注意と今後の改善（任意）
現仕様はトークン照合で全ユーザーを走査します。ユーザー数が多い場合は、検索用ハッシュ（例: SHA-256）を別カラムに保存してO(1)検索に改善可。
トークン期限（例: 90日）やローテーション方針をルール化するとより安全です。
API用リクエスト/システムテストの追加を推奨。