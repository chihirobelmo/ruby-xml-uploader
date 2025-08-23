require "test_helper"

class XmlDocumentsControllerTest < ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers

  setup do
    @doc = XmlDocument.new(title: "Sample XML", description: "Fixture file")
    # Attach a sample XML to the record before saving to pass validation
    @doc.xml_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.xml")),
      filename: "sample.xml",
      content_type: "application/xml"
    )
    @doc.save!
  end

  test "should get index as JSON" do
    get xml_documents_url(format: :json)
    assert_response :success

    body = JSON.parse(@response.body)
    assert_kind_of Array, body
    assert body.any?, "Expected at least one document in JSON response"
    item = body.find { |h| h["id"] == @doc.id }
    assert item, "Expected response to include created document"
    assert_equal "Sample XML", item["title"]
    assert item.key?("file"), "Expected file info key in response"
    assert item["file"].key?("url"), "Expected file.url in response"
  end
end
