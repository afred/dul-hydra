module DulHydra::Batch::Models
  
  class Batch < ActiveRecord::Base
    attr_accessible :description, :name, :user, :details, :failure, :logfile, :outcome, :start, :status, :stop, :success, :total, :version
    belongs_to :user, :inverse_of => :batches
    has_many :batch_objects, :inverse_of => :batch, :dependent => :destroy
    has_attached_file :logfile

    OUTCOME_SUCCESS = "SUCCESS"
    OUTCOME_FAILURE = "FAILURE"
    
    STATUS_RUNNING = "RUNNING"
    STATUS_FINISHED = "FINISHED"
    STATUS_INTERRUPTED = "INTERRUPTED"

    def validate
      errors = []
      batch_objects.each { |object| errors << object.validate }
      errors.flatten
    end
    
    def start_run
      update_attributes(
          :failure => 0,
          :start => DateTime.now,
          :status => STATUS_RUNNING,
          :success => 0,
          :version => DulHydra::VERSION
          )
    end
    
    def close_run(details)
      update_attributes(
          :details => details.nil? ? nil : details.join("\n"),
          :outcome => self.success.eql?(batch_objects.count) ? OUTCOME_SUCCESS : OUTCOME_FAILURE,
          :status => STATUS_FINISHED,
          :stop => DateTime.now
          )  
    end
    
  end
  
end