# encoding: UTF-8
# app/controllers/xml_documents_controller.rb
class XmlDocumentsController < ApplicationController
  before_action :require_login, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_xml_document, only: [:show, :edit, :update, :destroy, :download]

  def index
  # Eager-load attachment to avoid N+1 when rendering JSON
  @xml_documents = XmlDocument.with_attached_xml_file.all
  end

  def show
  end

  def new
    @xml_document = XmlDocument.new
  end

  def create
  @xml_document = XmlDocument.new(xml_document_params)
  @xml_document.user = current_user if user_signed_in?
    
    if @xml_document.save
  redirect_to @xml_document, notice: 'XML file uploaded successfully.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @xml_document.update(xml_document_params)
  redirect_to @xml_document, notice: 'XML file updated successfully.'
    else
      render :edit
    end
  end

  def destroy
    @xml_document.destroy
  redirect_to xml_documents_path, notice: 'XML file deleted successfully.'
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