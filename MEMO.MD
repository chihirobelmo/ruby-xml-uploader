1. Active Storage のセットアップ
Rails の Active Storage を使用してファイルアップロードを実装します：

```bash
rails active_storage:install
rails db:migrate
```

2. モデルの準備
XML ファイルを関連付けるモデルを作成します：

```bash
rails g model XmlDocument title:string description:text
rails db:migrate
```

3. モデルに Active Storage の関連付けを追加

```ruby
# app/models/xml_document.rb
class XmlDocument < ApplicationRecord
  has_one_attached :xml_file
  
  validates :title, presence: true
  validates :xml_file, presence: true, content_type: 'text/xml'
end
```

4. コントローラーの作成

```bash
rails g controller XmlDocuments
```

5. コントローラーの実装

```ruby
# app/controllers/xml_documents_controller.rb
class XmlDocumentsController < ApplicationController
  before_action :set_xml_document, only: [:show, :edit, :update, :destroy, :download]

  def index
    @xml_documents = XmlDocument.all
  end

  def show
  end

  def new
    @xml_document = XmlDocument.new
  end

  def create
    @xml_document = XmlDocument.new(xml_document_params)
    
    if @xml_document.save
      redirect_to @xml_document, notice: 'XMLファイルが正常にアップロードされました。'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @xml_document.update(xml_document_params)
      redirect_to @xml_document, notice: 'XMLファイルが正常に更新されました。'
    else
      render :edit
    end
  end

  def destroy
    @xml_document.destroy
    redirect_to xml_documents_path, notice: 'XMLファイルが正常に削除されました。'
  end

  def download
    redirect_to rails_blob_path(@xml_document.xml_file, disposition: "attachment")
  end

  private
    def set_xml_document
      @xml_document = XmlDocument.find(params[:id])
    end

    def xml_document_params
      params.require(:xml_document).permit(:title, :description, :xml_file)
    end
end
```

6. ビューの作成
フォーム用のパーシャル

```html
<!-- app/views/xml_documents/_form.html.erb -->
<%= form_with(model: xml_document, local: true) do |form| %>
  <% if xml_document.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(xml_document.errors.count, "error") %> prohibited this document from being saved:</h2>
      <ul>
      <% xml_document.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= form.label :title %>
    <%= form.text_field :title %>
  </div>

  <div class="field">
    <%= form.label :description %>
    <%= form.text_area :description %>
  </div>

  <div class="field">
    <%= form.label :xml_file %>
    <%= form.file_field :xml_file %>
  </div>

  <div class="actions">
    <%= form.submit "保存" %>
  </div>
<% end %>
```

```html
<!-- app/views/xml_documents/index.html.erb -->
<h1>XML ファイル一覧</h1>

<table>
  <thead>
    <tr>
      <th>タイトル</th>
      <th>説明</th>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @xml_documents.each do |document| %>
      <tr>
        <td><%= document.title %></td>
        <td><%= document.description %></td>
        <td><%= link_to '詳細', document %></td>
        <td><%= link_to 'ダウンロード', download_xml_document_path(document) %></td>
        <td><%= link_to '編集', edit_xml_document_path(document) %></td>
        <td><%= link_to '削除', document, method: :delete, data: { confirm: '本当に削除しますか？' } %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<br>

<%= link_to '新規XMLファイルアップロード', new_xml_document_path %>
```

7. ルーティングの設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :xml_documents do
    member do
      get :download
    end
  end
  
  root 'xml_documents#index'
end
```

8. Content Type の検証
アップロードする XML ファイルの content type を正しく検証するため、カスタムバリデーションを追加することも検討してください。

以上の実装で、XML ファイルのアップロード・ダウンロード機能を持つ基本的なアプリケーションが完成します。必要に応じて機能拡張してください。


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

ctive Storageでは、DBと実ファイルの結びつきは以下のように管理されています。

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

## ほかのアプリとの連携

> 例えばほかのアプリからREST APIを通じてファイルのアップロードやダウンロードも可能ですか

はい、他のアプリからREST API経由でファイルのアップロードやダウンロードも可能です。

主な方法
RailsコントローラにAPI用のエンドポイント（JSON/ファイル受け入れ）を追加
ファイルアップロードはmultipart/form-dataでPOST
ダウンロードはActive StorageのURLやAPIで返す

例：APIコントローラ（アップロード）

```ruby
class Api::XmlDocumentsController < ApplicationController
  protect_from_forgery with: :null_session

  def create
    @xml_document = XmlDocument.new(title: params[:title])
    @xml_document.xml_file.attach(params[:xml_file])
    if @xml_document.save
      render json: { id: @xml_document.id }, status: :created
    else
      render json: { errors: @xml_document.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
```

例：APIコントローラ（ダウンロード）

```ruby
def download
  if @xml_document.xml_file.attached?
    redirect_to rails_blob_url(@xml_document.xml_file, disposition: "attachment")
  else
    head :not_found
  end
end
```



> REST APIだと例えばどのようなコマンドの送信ができますか。例えばC#でこのAPIへファイルを送信するにはどうしますか

REST APIでファイルをアップロードする場合、multipart/form-data形式でPOSTリクエストを送信します。
C#の場合、HttpClientとMultipartFormDataContentを使ってファイルを送信できます。

```cs
using System.Net.Http;
using System.Threading.Tasks;

public async Task UploadXmlFileAsync(string apiUrl, string filePath, string title)
{
    using var client = new HttpClient();
    using var form = new MultipartFormDataContent();
    form.Add(new StringContent(title), "title");
    form.Add(new ByteArrayContent(System.IO.File.ReadAllBytes(filePath)), "xml_file", "sample.xml");

    var response = await client.PostAsync(apiUrl, form);
    string result = await response.Content.ReadAsStringAsync();
    // 結果の処理
}
```

```bash
curl -X POST http://localhost:3000/api/xml_documents \
  -F "title=sample" \
  -F "xml_file=@sample.xml"
```

C#でもcurlでも、

"title"はテキスト
"xml_file"はファイル（@ファイル名やByteArrayContent）
この形式でAPIに送信できます。

## ユーザ管理

Gemfileに次の行を追加して`bundle install`を行う

```ruby
gem "bcrypt", "~> 3.1"
```

追加: Userモデル（has_secure_password）
追加: サインアップ/ログイン/ログアウトのコントローラとビュー
変更: 認証ヘルパーとbefore_actionでXmlDocumentsのnew/create等を保護
変更: レイアウトにログイン状態とフラッシュを表示
変更: 一覧から未ログイン時は新規アップロードリンクを非表示
実行: bundle install, rails db:migrate

### 改善候補

- フラッシュのスタイル整備
- パスワード最小長などの追加バリデーション
- CSRF例外設定のAPI分離が必要ならAPI用のBaseControllerを切り出し

## remember_me

安全な永続ログイン用トークンを使い、サインイン時に署名付きCookieへ保存、次回アクセスで自動ログイン

- DB: usersにremember_digestを追加（マイグレーション済み）
- Model: Userにrememberトークン生成/検証/破棄のヘルパーを実装
- Controller:
  - ApplicationController.current_userでCookieからの自動復元に対応
  - SessionsControllerでremember_meチェックボックスを処理、Cookie設定/削除
- View: ログイン画面に「ログイン状態を保持する」チェックボックス追加

### 実装のポイント

- Cookieは署名付き（cookies.permanent.signed[:user_id]）とトークンの平文（remember_token）をそれぞれ保存
- DBにはハッシュ化したremember_digestのみ保持（トークン平文は保持しない）
- current_userはセッション → Cookieの順で復元、Cookie一致時はセッション再セット

### 改善候補

- CookieのSameSite/secure/httponlyのポリシー調整（本番はsecure: trueを推奨、HTTPS前提）
- rememberトークンの有効期限を短縮したい場合はpermanentではなく一定期間に
- 端末別にrememberを無効化したい場合はrememberトークンを別テーブルで複数持たせる運用に拡張

## 改善候補

注意と今後の改善（任意）
現仕様はトークン照合で全ユーザーを走査します。ユーザー数が多い場合は、検索用ハッシュ（例: SHA-256）を別カラムに保存してO(1)検索に改善可。
トークン期限（例: 90日）やローテーション方針をルール化するとより安全です。
API用リクエスト/システムテストの追加を推奨。