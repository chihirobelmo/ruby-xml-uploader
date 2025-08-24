# encoding: UTF-8
module Api
  class XmlDocumentsController < ApplicationController
  include ApiAuthenticatable
  skip_before_action :authenticate_bearer!, only: [:index, :download]
  protect_from_forgery with: :null_session

    # GET /api/xml_documents.json (public)
    def index
      scope = XmlDocument.with_attached_xml_file.includes(:user).order(created_at: :desc)

      # Optional filtering by multiple device names
      # Accepts: ?device_name=Foo,Bar or ?device_name[]=Foo&device_name[]=Bar or ?device_names=Foo,Bar
      names_param = params[:device_name].presence || params[:device_names].presence
      names = Array(names_param).flat_map { |v| v.to_s.split(',') }
            .map { |s| s.to_s.strip }
            .reject(&:blank?).uniq
      scope = scope.where(device_name: names) if names.present?

      @xml_documents = scope
      respond_to do |format|
        format.json { render template: "xml_documents/index", formats: :json }
        format.any  { render json: { error: "Not Acceptable" }, status: :not_acceptable }
      end
    end

    # GET /api/xml_documents/:id/download (public)
    def download
      doc = XmlDocument.find(params[:id])
      unless doc.xml_file.attached?
        render json: { error: 'Not Found' }, status: :not_found and return
      end

      # Only count on real GET requests (skip HEAD)
      if request.get?
        api_user = nil
        # Attribute to user if a valid Bearer token is present (optional)
        if respond_to?(:bearer_token_from_header)
          token = bearer_token_from_header
          api_user = User.authenticate_api_token(token) if token.present?
        end

        XmlDownload.create!(
          xml_document: doc,
          user: api_user,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          session_id: request.session_options[:id]
        )
      end

      redirect_to rails_blob_path(doc.xml_file, disposition: "attachment")
    end

    # POST /api/xml_documents (protected: Bearer)
    # Accepts multipart/form-data:
    #   - title (required)
    #   - description (optional)
    #   - xml_file (required) => attached file
    def create
      title       = params.dig(:xml_document, :title) || params[:title]
      description = params.dig(:xml_document, :description) || params[:description]
      file_param  = params.dig(:xml_document, :xml_file) || params[:xml_file]

      xml_document = XmlDocument.new(title: title, description: description)
      xml_document.user = current_api_user if defined?(current_api_user)
      xml_document.xml_file.attach(file_param) if file_param.present?

      if xml_document.save
        render json: { id: xml_document.id, title: xml_document.title, device_name: xml_document.device_name }, status: :created
      else
        render json: { errors: xml_document.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
