module DulHydra::Batch::Scripts
  class FolderBatch
   
    FILE_OBJECT_MODEL = 'Component'
   
    # Options
    #   :dirpath - required - path to directory tree containing files to be ingested
    #   :username - required - username of user with whom to associate batch
    
    def initialize(opts={})
      @dirpath = opts.fetch(:dirpath)
      @username = opts.fetch(:username)
    end
    
    def execute
      create_batch(User.find_by_username(@username))
      process_files(@dirpath)
    end
    
    def process_files(dirpath)
      Dir.foreach(dirpath) do |entry|
        unless [".", ".."].include?(entry)
          if File.directory?(File.join(dirpath, entry))
            process_files(File.join(dirpath, entry))
          else
            create_batch_object_for_file(entry)
          end
        end
      end      
    end
    
    def create_batch_object_for_file(file_entry)
      obj = DulHydra::Batch::Models::IngestBatchObject.new(
              :batch => @batch,
              :model => FILE_OBJECT_MODEL
              )
      obj.save
      obj.process
    end

    def create_batch(user)
      @batch = DulHydra::Batch::Models::Batch.create(:user => user)
    end
    
  end
end