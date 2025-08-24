require "test_helper"

class XmlDocumentsDownloadTest < ActionDispatch::IntegrationTest
  setup do
    @doc = XmlDocument.new(title: "DL Action", description: "desc")
    @doc.xml_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    @doc.save!
  end

  test "download creates a download event" do
    assert_difference -> { XmlDownload.count }, +1 do
      get download_xml_document_path(@doc)
      assert_response :redirect
    end
  end
end
