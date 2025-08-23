require "test_helper"

class Api::XmlDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @doc = XmlDocument.new(title: "API Sample", description: "For API test")
    @doc.xml_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    @doc.save!
  end

  test "GET /api/xml_documents.json returns list" do
    get "/api/xml_documents.json"
    assert_response :success
    body = JSON.parse(@response.body)
    assert_kind_of Array, body
    item = body.find { |h| h["id"] == @doc.id }
    assert item, "expected to include the created document"
    assert_equal "API Sample", item["title"]
  end
end
