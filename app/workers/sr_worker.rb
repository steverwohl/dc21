#!/usr/bin/ruby -w

class SRWorker
  include Resque::Plugins::Status

  @queue = :sr_queue

  def perform
    df = DataFile.find(options['data_file_id'])
    begin

      user = df.created_by

      job = Resque::Plugins::Status::Hash.get(df.uuid)
      df.transfer_status = job.status.to_s.upcase

      df.save

      df.file_processing_description = df.file_processing_description + "\n This was processed by SRWorker at #{Time.now}."

      df.save

      df.mark_as_complete

    rescue Exception => e
      # Catch exception, set transfer status and rethrow so we can see what went wrong in the overview page
      df.mark_as_failed
      raise e
    end
  end

end