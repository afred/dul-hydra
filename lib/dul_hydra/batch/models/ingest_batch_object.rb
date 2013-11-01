module DulHydra::Batch::Models
  
  class IngestBatchObject < DulHydra::Batch::Models::BatchObject
  
    def validate_required_attributes
      errs = []
      errs << "#{@error_prefix} Model required for INGEST operation" unless model
      errs
    end
  
    def process
      ingest
    end
    
    private
    
    Results = Struct.new(:repository_object, :verified, :verifications)
  
    def ingest
      repo_object = create_repository_object
      if !repo_object.nil?
        ingest_outcome_detail = []
        ingest_outcome_detail << "Ingested #{model} #{identifier} into #{repo_object.pid}"
        create_preservation_event(PreservationEvent::INGESTION,
                                  PreservationEvent::SUCCESS,
                                  ingest_outcome_detail,
                                  repo_object)
        update_attributes(:pid => repo_object.pid)
        verifications = verify_repository_object
        verification_outcome_detail = []
        verified = true
        verifications.each do |key, value|
          verification_outcome_detail << "#{key}...#{value}"
          verified = false if value.eql?(VERIFICATION_FAIL)
        end
        update_attributes(:verified => verified)
        create_preservation_event(PreservationEvent::VALIDATION,
                                  verified ? PreservationEvent::SUCCESS : PreservationEvent::FAILURE,
                                  verification_outcome_detail,
                                  repo_object)
      else
        verifications = nil
      end
      Results.new(repo_object, verified, verifications)
    end
    
    def create_repository_object
      repo_object = model.constantize.new
      repo_object.label = label if label
      repo_object.save
      batch_object_datastreams.each {|d| repo_object = add_datastream(repo_object, d)} if batch_object_datastreams
      batch_object_relationships.each {|r| repo_object = add_relationship(repo_object, r)} if batch_object_relationships
      repo_object.save
      repo_object
    end  
  
  end

end