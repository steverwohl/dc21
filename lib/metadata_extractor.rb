class MetadataExtractor

  def extract_metadata(data_file, type, force=false)
    config = SystemConfiguration.instance
    if type == FileTypeDeterminer::TOA5
      Toa5Parser.extract_metadata(data_file)
    elsif config.auto_ocr?(data_file, force)
      builder = AttachmentBuilder.new(APP_CONFIG['files_root'], data_file.created_by, FileTypeDeterminer.new, MetadataExtractor.new)
      output_file = builder.build_output_data_file(data_file, '.txt')
      output_file.uuid = OCRWorker.create({output_id: output_file.id, parent_id: data_file.id})
      output_file.parents << data_file
      output_file.save
    elsif config.auto_sr?(data_file, force)
      builder = AttachmentBuilder.new(APP_CONFIG['files_root'], data_file.created_by, FileTypeDeterminer.new, MetadataExtractor.new)
      output_file = builder.build_output_data_file(data_file, '.txt')
      output_file.uuid = SRUploadWorker.create({output_id: output_file.id, parent_id: data_file.id})
      output_file.parents << data_file
      output_file.save
    end
  end
end
