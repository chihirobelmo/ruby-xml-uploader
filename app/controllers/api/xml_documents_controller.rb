# encoding: UTF-8
module Api
  class XmlDocumentsController < ApplicationController
    include ApiAuthenticatable

    # GET /api/xml_documents.json
    def index
      docs = XmlDocument.with_attached_xml_file.includes(:user).order(created_at: :desc)
      render json: docs.map { |d| serialize_doc(d) }
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
