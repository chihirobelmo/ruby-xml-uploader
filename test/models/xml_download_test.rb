require "test_helper"

class XmlDownloadTest < ActiveSupport::TestCase
  test "valid with xml_document" do
    doc = XmlDocument.new(title: "DL Test", description: "desc")
    doc.xml_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    assert doc.save!

    event = XmlDownload.new(xml_document: doc, ip: "127.0.0.1", user_agent: "test")
    assert event.valid?
    assert event.save!
  end
end
