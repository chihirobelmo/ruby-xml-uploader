# DB初期化

1) まるっと初期化（Drop→Create→Schema+Seeds）

```
bin/rails db:reset
# 追加のseedがあれば
bin/rails db:seed
```

2) 手順を分けたい場合

```
bin/rails db:drop
bin/rails db:create
bin/rails db:migrate
```

3) テストDBもクリアしたい場合

```
RAILS_ENV=test bin/rails db:reset
```

オプション:

アップロード済みファイル（Active Storage）も消したい場合は、DBリセット後にストレージも削除してください。SQLiteもstorage配下にあるため、併せて消えます。

```
rm -rf storage/*
# その後、必要ならDBを再作成
bin/rails db:setup
```