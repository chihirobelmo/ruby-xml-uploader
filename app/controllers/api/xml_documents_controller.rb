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
      if doc.xml_file.attached?
        redirect_to rails_blob_path(doc.xml_file, disposition: "attachment")
      else
        render json: { error: 'Not Found' }, status: :not_found
      end
    end
  end
end
