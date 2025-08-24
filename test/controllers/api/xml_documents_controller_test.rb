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

  test "GET /api/xml_documents.json returns only latest per user/title/device" do
    # Create a user and two docs with same title/device for that user
    user = User.create!(email: "dup@example.com", username: "dupuser", password: "secret123", password_confirmation: "secret123")
    older = XmlDocument.new(title: "Same", description: "older", user: user)
    older.xml_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.xml")),
      filename: "Setup.v100.DeviceA {11111111-1111-1111-1111-111111111111}.xml",
      content_type: "application/xml"
    )
    older.save!

    sleep 1 # ensure created_at differs

    newer = XmlDocument.new(title: "Same", description: "newer", user: user)
    newer.xml_file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample.xml")),
      filename: "Setup.v100.DeviceA {22222222-2222-2222-2222-222222222222}.xml",
      content_type: "application/xml"
    )
    newer.save!

    get "/api/xml_documents.json"
    assert_response :success
    body = JSON.parse(@response.body)

    # Filter by grouping key; expect only the newer one present
    group_items = body.select { |h| h["title"] == "Same" && h["device_name"] == "DeviceA" && h["username"] == "dupuser" }
    assert_equal 1, group_items.size, "expected only one item per user/title/device group"
    assert_equal newer.id, group_items.first["id"], "expected the newest document to be returned"
  end
end
