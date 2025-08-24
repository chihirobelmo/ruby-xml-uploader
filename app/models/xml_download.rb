# encoding: UTF-8
class XmlDownload < ApplicationRecord
  belongs_to :xml_document
  belongs_to :user, optional: true

  validates :xml_document, presence: true
end
