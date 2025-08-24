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

  test "JSON includes aggregated download_count for user/title/device group" do
    user = User.create!(email: "count@example.com", username: "counter", password: "secret123", password_confirmation: "secret123")
    # Create two docs in the same group
    d1 = XmlDocument.new(title: "Agg", description: "one", user: user)
    d1.xml_file.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.xml")), filename: "Setup.v100.DeviceX {A}.xml", content_type: "application/xml")
    d1.save!
    d2 = XmlDocument.new(title: "Agg", description: "two", user: user)
    d2.xml_file.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.xml")), filename: "Setup.v100.DeviceX {B}.xml", content_type: "application/xml")
    d2.save!

    # Create download events: 2 for d1, 3 for d2 (total 5)
    2.times { XmlDownload.create!(xml_document: d1) }
    3.times { XmlDownload.create!(xml_document: d2) }

    get "/api/xml_documents.json"
    assert_response :success
    body = JSON.parse(@response.body)
    item = body.find { |h| h["title"] == "Agg" && h["device_name"] == "DeviceX" && h["username"] == "counter" }
    assert item, "expected aggregated item present"
    assert_equal 5, item["download_count"], "expected aggregated download_count across group"
  end

  test "JSON is sorted by download_count desc (then created_at)" do
    user = User.create!(email: "sort@example.com", username: "sorter", password: "secret123", password_confirmation: "secret123")
    # Group A with 1 download
    a = XmlDocument.new(title: "S", description: "a", user: user)
    a.xml_file.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.xml")), filename: "Setup.v100.DeviceS {A1}.xml", content_type: "application/xml")
    a.save!
    XmlDownload.create!(xml_document: a)

    # Group B with 3 downloads
    b = XmlDocument.new(title: "T", description: "b", user: user)
    b.xml_file.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.xml")), filename: "Setup.v100.DeviceT {B1}.xml", content_type: "application/xml")
    b.save!
    3.times { XmlDownload.create!(xml_document: b) }

    get "/api/xml_documents.json"
    assert_response :success
    body = JSON.parse(@response.body)
    # First item should be the higher download_count group (B)
    assert_equal "T", body.first["title"]
  end
end
