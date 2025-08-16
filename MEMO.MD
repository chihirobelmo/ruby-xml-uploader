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