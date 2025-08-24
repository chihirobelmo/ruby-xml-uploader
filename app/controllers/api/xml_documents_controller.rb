# encoding: UTF-8
module Api
  class XmlDocumentsController < ApplicationController
  include ApiAuthenticatable
  skip_before_action :authenticate_bearer!, only: [:index, :download]

    # GET /api/xml_documents.json (public)
    def index
      docs = XmlDocument.with_attached_xml_file.includes(:user).order(created_at: :desc)
      render json: docs.map { |d| serialize_doc(d) }
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

    private

    def serialize_doc(d)
      {
        id: d.id,
        title: d.title,
        description: d.description,
        created_at: d.created_at,
        updated_at: d.updated_at,
        user: d.user && { id: d.user.id, email: d.user.email, username: d.user.username },
        xml_file_url: (d.xml_file.attached? ? url_for(d.xml_file) : nil)
      }
    end
  end
end
