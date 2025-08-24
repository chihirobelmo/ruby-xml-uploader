# encoding: UTF-8
module Api
  class XmlDocumentsController < ApplicationController
  include ApiAuthenticatable
  skip_before_action :authenticate_bearer!, only: [:index, :download]

    # GET /api/xml_documents.json (public)
    def index
      @xml_documents = XmlDocument.with_attached_xml_file.includes(:user).order(created_at: :desc)
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
  end
end
