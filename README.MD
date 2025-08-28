# XML Uploader Backend

Backend server for an online joystick configuration upload/download service. It pairs with the Windows client shown in:
https://github.com/chihirobelmo/FalconBMS-Launcher/tree/feature/online-setup-downloader

## Features
- Upload, list, and download XML files (Active Storage: Disk by default)
- User authentication (session + optional "remember me") and API Bearer tokens
- Device name extraction from XML filename (stored as `device_name`)
- Download event logging (IP, user agent, session, optional user)
- Public JSON listing with optional filtering by `device_name`

## Tech Stack
- Ruby 3.4.5 / Rails ~> 8.0.2
- SQLite (development/test), Puma, Importmap, Turbo/Stimulus
- Active Storage (Disk in dev/prod; S3 configurable)
- Solid Cache/Queue in production (prepared), Kamal for deploy (optional)

## Quick Start (Local)
Prerequisites: Ruby 3.4.5, Bundler, SQLite3.

1. Install gems
	 - bundle install
2. Setup database and Active Storage tables
	 - bin/rails db:setup
3. Run the server (http://localhost:3000)
	 - bin/rails server

Notes
- Development and production default to `config.active_storage.service = :local`.
- To switch to S3, see Configuration below.

## Architecture Overview
Client (Browser/Windows app) -> Rails (Controllers) -> Models/Active Storage -> DB + storage -> Views/JSON

Main relations
- User 1?* XmlDocument 1?* XmlDownload
- XmlDocument ?1 ActiveStorage attachment (`xml_file`)

## API Quick Reference (for Windows client)

Auth (token issuance)
- POST /api/token
	- Body: { "email": "user@example.com", "password": "..." }
	- 201 -> { "token": "..." }, 401 on failure
- DELETE /api/token
	- Header: Authorization: Bearer <token>
	- 204 on success, 401 if invalid

List XMLs (public JSON)
- GET /api/xml_documents.json
	- Optional filter: `?device_name=A,B` or `?device_name[]=A&device_name[]=B`
	- 200 -> JSON array of documents (title, device_name, etc.)

Upload XML (protected)
- POST /api/xml_documents
	- Header: Authorization: Bearer <token>
	- multipart/form-data: `title` (req), `description` (opt), `xml_file` (req)
	- 201 -> { id, title, device_name }, 422 on validation errors

Download (public redirect to blob)
- GET /api/xml_documents/:id/download
	- 302 -> Active Storage blob URL (attachment disposition)

### Example Responses
- Token create (201)
	- { "token": "<once-shown-token>" }
- Upload success (201)
	- { "id": 123, "title": "My XML", "device_name": "WINWING Orion Joystick Base 2 JGRIP-F16" }
- Error (401/422)
	- { "error": "Unauthorized" } or { "errors": ["Title can't be blank", "Xml file can't be blank"] }

## Configuration
Active Storage
- Default services (see `config/storage.yml`): `:local` for dev/prod, `:test` for tests.
- S3 example (commented in `storage.yml`). Provide credentials via Rails credentials or env vars and set:
	- production: `config.active_storage.service = :amazon`

Security/SSL
- Production assumes SSL (`assume_ssl` + `force_ssl`). Place behind an HTTPS reverse proxy.

## Data Model (high level)
- users: email, password_digest, username, remember_digest, api_token_digest, api_token_generated_at
- xml_documents: title, description, device_name, user_id, timestamps
- xml_downloads: xml_document_id, user_id, ip, user_agent, session_id, timestamps
- active_storage_blobs/attachments: file metadata and attachment linkage

## Security Notes
- Web session and API Bearer token are separate. Token is stored as a digest in DB; raw token is returned once.
- Upload validation: `title` required, XML file required. Consider adding size/MIME/XML well-formed checks in production.
- Download events are logged for audit/analytics.

## Testing
- Gems: RSpec is not configured; Rails default test with Capybara/Selenium available.
- Suggested scenarios: login -> upload -> list -> download; unauthorized access rejection; API contract tests.
- Run
	- bin/rails test

## Deployment
- Dockerfile and Kamal are included (optional). Configure environment, SSL termination, and Active Storage service.
- Maintenance: schedule cleanup for unattached blobs and monitor disk usage.

## Roadmap / Known items
- Tighten authorization (owner scoping) on HTML endpoints if needed
- Add content-type/size/XML validation and anti-XXE hardening
- System/Request tests for happy path and permission boundaries
- Optional: S3 integration in production, signed URLs, background processing for large files

