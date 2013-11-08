#!/usr/bin/ruby -w
require 'tesseract'

class OCRWorker
  include Resque::Plugins::Status

  @queue = :ocr_queue

  def perform
    begin
      @total_processed = 0

      df = DataFile.find(options['data_file_id'])
      user = df.created_by

      job = Resque::Plugins::Status::Hash.get(df.uuid)
      df.transfer_status = job.status.to_s.upcase

      df.save

      # build tesseract txt file
      e = Tesseract::Engine.new {|e|
        e.language = :eng
        e.blacklist = ''
      }
      df.converted_text = e.text_for(df.path).strip
      # create attachment

      #attachment_builder = AttachmentBuilder.new(APP_CONFIG['files_root'], user, FileTypeDeterminer.new, MetadataExtractor.new)
      #files = attachment_builder.build(file, experiment_id, type, description, tags, labels)


      df.save

      # Since the parent of the action can't update it
      df.mark_as_complete

      # Send email indicating its complete
      #Notifier.notify_user_of_completed_package(df).deliver

    rescue Exception => e
      # Catch exception, set transfer status and rethrow so we can see what went wrong in the overview page
      df.mark_as_failed
      raise e
    end
  end

end