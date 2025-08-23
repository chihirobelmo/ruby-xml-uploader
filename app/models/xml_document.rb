# encoding: UTF-8
class XmlDocument < ApplicationRecord
    belongs_to :user, optional: true
    has_one_attached :xml_file

    validates :title, presence: true
    validate :xml_file_presence
    before_validation :extract_device_name_from_filename

    def xml_file_presence
    errors.add(:xml_file, 'を添付してください') unless xml_file.attached?
    end

        private

        # Extract device name from filenames like:
        #   "Setup.v100.WINWING Orion Joystick Base 2  JGRIP-F16 {UUID}.xml"
        # We capture the part between the second dot and the opening brace " {" or the trailing .xml
        def extract_device_name_from_filename
        return unless xml_file.attached?
        # Avoid errors if migration hasn't been applied in the current environment
        return unless has_attribute?(:device_name)
            name = xml_file.filename.to_s
            # Remove extension
            base = name.sub(/\.xml\z/i, '')
            # Strip trailing UUID block if present: " {....}"
            base = base.sub(/\s*\{[^}]+\}\z/, '')
            # Split by dots and take the part after the version token (e.g., v100)
            parts = base.split('.')
            if parts.length >= 3
                candidate = parts[2..].join('.')
            else
                # Fallback: everything after first space in "Setup <device>"
                candidate = base.sub(/^Setup\s*/i, '')
            end
            self[:device_name] = candidate.strip.presence
        end
end
