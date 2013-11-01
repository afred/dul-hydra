module DulHydra::Batch::Jobs
  class FolderBatchProcessorJob < Struct.new(:dirpath, :username)
    
    def perform
      ts = Time.now.to_i
      logfile = "batch_processor_#{ts}.log"
      fb = DulHydra::Batch::Scripts::FolderBatch.new(:dirpath => dirpath, :username => username, :log_file => logfile)
      fb.execute
    end
    
    # def failure(job)
    #   batch = DulHydra::Batch::Models::Batch.find(batch_id)
    #   batch.stop = Time.now
    #   batch.outcome = DulHydra::Batch::Models::Batch::OUTCOME_FAILURE
    #   batch.status = DulHydra::Batch::Models::Batch::STATUS_INTERRUPTED
    #   batch.save
    # end
    
  end
end