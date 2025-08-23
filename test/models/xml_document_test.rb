require "test_helper"

class XmlDocumentTest < ActiveSupport::TestCase
  test "extracts device_name from attached file name" do
    doc = XmlDocument.new(title: "t")
    doc.xml_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.xml")),
      filename: "Setup.v100.WINWING Orion Joystick Base 2  JGRIP-F16 {369F5AF0-0FF6-11F0-8001-444553540000}.xml",
      content_type: "application/xml"
    )
    assert doc.valid?, doc.errors.full_messages.join(", ")
    assert_equal "WINWING Orion Joystick Base 2  JGRIP-F16", doc.device_name
  end
end
