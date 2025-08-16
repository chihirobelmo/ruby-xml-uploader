# encoding: UTF-8
class XmlDocument < ApplicationRecord
  has_one_attached :xml_file

  validates :title, presence: true
  validates :xml_file, presence: true
  validate :xml_file_type

  private

  def xml_file_type
    if xml_file.attached? && xml_file.content_type != 'text/xml'
      errors.add(:xml_file, 'はXMLファイルのみアップロードできます')
    end
  end
end
