# encoding: UTF-8
class XmlDocument < ApplicationRecord
  has_one_attached :xml_file
  
  validates :title, presence: true
  validates :xml_file, presence: true, content_type: 'text/xml'
end
