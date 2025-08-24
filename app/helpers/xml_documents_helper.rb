module XmlDocumentsHelper
	def download_count_for(document, preloaded_counts = nil)
		return preloaded_counts[document.id] if preloaded_counts && preloaded_counts.key?(document.id)
		XmlDownload.where(xml_document_id: document.id).count
	end
end
