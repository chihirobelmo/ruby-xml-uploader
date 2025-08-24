# encoding: UTF-8
module Api
  class XmlDocumentsController < ApplicationController
    # Public JSON API listing uploaded XML documents
    def index
  @xml_documents = XmlDocument.with_attached_xml_file.includes(:user).order(created_at: :desc)
      respond_to do |format|
        format.json { render template: "xml_documents/index", formats: :json }
        format.any  { render json: { error: "Not Acceptable" }, status: :not_acceptable }
      end
    end
  end
end
