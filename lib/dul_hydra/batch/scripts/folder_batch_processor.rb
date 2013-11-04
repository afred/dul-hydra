module DulHydra::Batch::Scripts
  class FolderBatchProcessor
   
    FILE_OBJECT_MODEL = 'Component'
    LOG_CONFIG_FILEPATH = File.join(Rails.root, 'config', 'log4r_batch_processor.yml')
    DEFAULT_LOG_DIR = File.join(Rails.root, 'log')
    DEFAULT_LOG_FILE = "batch_processor.log"
   
    # Options
    #   :dirpath - required - path to directory tree containing files to be ingested
    #   :username - required - username of user with whom to associate batch
    #   :collection_pid - optional - PID of the collection to which items should be children
    #   :log_dir - optional - directory for log file - default is given in DEFAULT_LOG_DIR
    #   :log_file - optional - filename of log file - default is given in DEFAULT_LOG_FILE
    
    def initialize(opts={})
      @dirpath = opts.fetch(:dirpath)
      @username = opts.fetch(:username)
      @log_dir = opts.fetch(:log_dir, DEFAULT_LOG_DIR)
      @log_file = opts.fetch(:log_file, DEFAULT_LOG_FILE)
    end
    
    def execute
      config_logger
      create_batch(User.find_by_username(@username))
      initiate_batch_run
      process_files(@dirpath)
      close_batch_run
      save_logfile
      send_notification if @batch.user && @batch.user.email
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
      obj.verified ? @batch.success += 1 : @batch.failure += 1
      if obj.pid
        verification_result = (obj.verified ? "Verified" : "VERIFICATION FAILURE")
        message = "Ingested #{obj.model} #{file_entry} into #{obj.pid}...#{verification_result}"
      else
        message = "Attempt to ingest #{obj.model} #{file_entry} FAILED"
      end
      @details << message
      @log.info(message)
    end

    def initiate_batch_run
      @log.info "Batch id: #{@batch.id}"
      @log.info "Batch name: #{@batch.name}" if @batch.name
      @batch.start_run
      @details = []
    end
    
    def close_batch_run
      @batch.close_run(@details)
      @log.info "Ingested #{@batch.success} of #{@batch.batch_objects.size} objects"
    end
    
    def create_batch(user)
      @batch = DulHydra::Batch::Models::Batch.create(
                :user => user,
                :name => "Folder Batch",
                :description => @dirpath
                )
    end
    
    def config_logger
      logconfig = Log4r::YamlConfigurator
      logconfig['LOG_FILE'] = File.join(@log_dir, @log_file)
      logconfig.load_yaml_file File.join(LOG_CONFIG_FILEPATH)
      @log = Log4r::Logger['batch_processor']
    end
    
    def save_logfile
      @log.outputters.each do |outputter|
        @logfilename = outputter.filename if outputter.respond_to?(:filename)
      end
      @batch.update_attributes({:logfile => File.new(@logfilename)}) if @logfilename
    end
    
    def send_notification
      begin
        BatchProcessorRunMailer.send_notification(@batch).deliver!
      rescue
        puts "An error occurred while attempting to send the notification."
      end
    end
    
  end
end