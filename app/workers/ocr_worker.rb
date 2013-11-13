#!/usr/bin/ruby -w


class OCRWorker
  include Resque::Plugins::Status

  @queue = :ocr_queue

  def perform
    df = DataFile.find(options['data_file_id'])

    begin
      @total_processed = 0
      user = df.created_by

      job = Resque::Plugins::Status::Hash.get(df.uuid)
      df.transfer_status = job.status.to_s.upcase

      df.save

      tmp = Tempfile.new('dc21_ocr')
      system *%W(tesseract #{df.path} #{tmp.path})
      df.converted_text = `cat "#{tmp.path}.txt"`

      df.save

      df.mark_as_complete

    rescue Exception => e
      # Catch exception, set transfer status and rethrow so we can see what went wrong in the overview page
      df.mark_as_failed
      raise e
    end
  end

end
