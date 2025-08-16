# encoding: UTF-8
class XmlDocument < ApplicationRecord
    has_one_attached :xml_file

    validates :title, presence: true
    validate :xml_file_presence

    def xml_file_presence
    errors.add(:xml_file, 'を添付してください') unless xml_file.attached?
    end
end
