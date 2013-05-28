class ManifestObject
  
  AUTOIDLENGTH = "autoidlength"
  BATCHID = "batchid"
  CHECKSUM = "checksum"
  DATASTREAMS = "datastreams"
  ID = "id"
  IDENTIFIER = "identifier"
  LABEL = "label"
  MODEL = "model"
  PID = "pid"
  TYPE = "type"
  VALUE = "value"

  OBJECT_KEYS = [ CHECKSUM, DATASTREAMS, IDENTIFIER, LABEL, MODEL, BatchObjectDatastream::DATASTREAMS, BatchObjectRelationship::RELATIONSHIPS].flatten
  OBJECT_CHECKSUM_KEYS = [ TYPE, VALUE ]
  OBJECT_RELATIONSHIP_KEYS = [ AUTOIDLENGTH, BATCHID, ID, PID ]

  def initialize(object_hash, manifest)
    @object_hash = object_hash
    @manifest = manifest
  end
  
  def validate
    errors = []
    errors += validate_identifier
    errors += validate_model
    errors += validate_keys
    errors += validate_datastreams if datastreams
    errors += validate_checksum_type if checksum_type?
    BatchObjectRelationship::RELATIONSHIPS.each do |relationship|
      if has_relationship?(relationship)
        errors += validate_relationship(relationship)
      end
    end
    return errors
  end

  def validate_relationship(relationship)
    errs = []
    pid = relationship_pid(relationship)
    obj = ActiveFedora::Base.find(pid, :cast => true) rescue errs << "Cannot find manifest object #{key_identifier} #{relationship} object in repository: #{pid}"
    object_class = DulHydra::Utils.reflection_object_class(DulHydra::Utils.relationship_object_reflection(model, relationship))
    errs << "Manifest object #{key_identifier} #{relationship} object should be a(n) #{object_class} but is a(n) #{obj.class}" unless obj.is_a?(object_class)
    return errs
  end
  
  def validate_datastream_filepath(datastream)
    errs = []
    filepath = datastream_filepath(datastream)
    errs << "Datastream filepath for manifest object #{key_identifier} is not readable: #{datastream} - #{filepath}" unless File.readable?(filepath)
    return errs
  end
  
  def validate_datastreams
    errs = []
    datastreams.each do |ds|
      errs << "Invalid datastream name for manifest object #{key_identifier}: #{ds}" unless BatchObjectDatastream::DATASTREAMS.include?(ds)
      errs << validate_datastream_filepath(ds)
    end
    return errs.flatten
  end
  
  def validate_checksum_type
    errs = []
    unless DulHydra::Datastreams::CHECKSUM_TYPES.include?(checksum_type)
      errs << "Invalid checksum type for manifest object #{key_identifier}: #{checksum_type}"
    end
    return errs
  end
  
  def validate_model
    errs = []
    if model
      model.constantize.new rescue errs << "Invalid model for manifest object #{key_identifier}: #{model}"
    else
      errs << "Missing model for manifest object #{key_identifier}"
    end    
    return errs
  end
  
  def validate_identifier
    errs = []
    errs << "Manifest object does not contain an identifier" unless key_identifier
    return errs
  end
  
  def validate_keys
    errs = []
    object_hash.keys.each do |key|
      errs << "Invalid key in manifest object #{key_identifier}: #{key}" unless OBJECT_KEYS.include?(key)
      case 
      when key.eql?(CHECKSUM)
        if object_hash[CHECKSUM].is_a?(Hash)
          object_hash[CHECKSUM].keys.each do |subkey|
            "Invalid subkey in manifest object #{key_identifier}: #{CHECKSUM} - #{subkey}" unless OBJECT_CHECKSUM_KEYS.include?(subkey)
          end
        end
      when BatchObjectRelationship::RELATIONSHIPS.include?(key)
        if object_hash[key].is_a?(Hash)
          object_hash[key].keys.each do |subkey|
            "Invalid subkey in manifest object #{key_identifier}: #{key} - #{subkey}" unless OBJECT_RELATIONSHIP_KEYS.include?(subkey)
          end
        end
      end
    end
    return errs
  end
  
  def batch
    manifest.batch
  end
  
  def checksum
    if object_hash[CHECKSUM]
      if object_hash[CHECKSUM][VALUE]
        object_hash[CHECKSUM][VALUE]
      else
        object_hash[CHECKSUM]
      end
    else
      if manifest.checksums?
        checksums = manifest.checksums
        checksum_node = checksums.xpath("#{manifest.checksum_node_xpath}[#{manifest.checksum_identifier_element}[text() = '#{key_identifier}']]")
        checksum_node.xpath(manifest.checksum_value_xpath).text()
      end
    end
  end
  
  def checksum?
    object_hash[CHECKSUM] || manifest.checksums? ? true : false
  end

  def checksum_type
    case
    when object_hash[CHECKSUM] && object_hash[CHECKSUM][TYPE]
      object_hash[CHECKSUM][TYPE]
    when manifest.checksums?
      checksums = manifest.checksums
      checksum_node = checksums.xpath("#{manifest.checksum_node_xpath}[#{manifest.checksum_identifier_element}[text() = '#{key_identifier}']]")
      checksum_node.xpath(manifest.checksum_type_xpath).text()
    when manifest.checksum_type
      manifest.checksum_type
    end    
  end

  def checksum_type?
    (object_hash[CHECKSUM] && object_hash[CHECKSUM][TYPE]) || manifest.checksums? || manifest.checksum_type?
  end

  def datastream_filepath(datastream_name)
    datastream = object_hash[datastream_name]
    filepath = case
      # canonical location is @manifest["basepath"] + datastream (name)
      # canonical filename is batch_object.identifier
      # canonical extension is ".xml"
    when datastream.nil?
      # (manifest datastream location || canonical location) + canonical filename + (manifest datastream extension || canonical extension)
      location = manifest.datastream_location(datastream_name) || File.join(manifest.basepath, datastream_name)
      extension = manifest.datastream_extension(datastream_name) || ".xml"
      File.join(location, key_identifier + extension)
    when datastream.start_with?(File::SEPARATOR)
      # datastream contains full path, file name, and extension
      datastream
    else
      # (manifest datastream location || canonical location) + datastream
      location = manifest.datastream_location(datastream_name) || File.join(manifest.basepath, datastream_name)
      File.join(location, datastream)
    end
  end
  
  def datastreams
    object_hash[DATASTREAMS] || manifest.datastreams
  end
  
  def key_identifier
    case object_hash[IDENTIFIER]
    when String
      object_hash[IDENTIFIER]
    when Array
      object_hash[IDENTIFIER].first
    end
  end
  
  def label
    object_hash[LABEL] || manifest.label
  end
  
  def model
    object_hash[MODEL] || manifest.model
  end
  
  def manifest
    @manifest
  end
  
  def manifest=(manifest)
    @manifest = manifest
  end
  
  def object_hash
    @object_hash
  end
  
  def object_hash=(object_hash)
    @object_hash = object_hash
  end

  def has_relationship?(relationship_name)
    object_hash[relationship_name] || manifest.has_relationship?(relationship_name) ? true : false
  end
  
  def relationship_pid(relationship_name)
    pid = explicit_relationship_pid(relationship_name)
    unless pid
      id = relationship_id(relationship_name)
      unless id
        autoidlength = relationship_autoidlength(relationship_name)
        if autoidlength
          index = autoidlength - 1
          id = key_identifier[0..index]
        end
      end
      if id
        batchid = relationship_batchid(relationship_name)
        if batchid
          found_objects = BatchObject.where("identifier = ? and batch_id = ?", id, batchid)
          if found_objects.size.eql?(1)
            found_object = found_objects.first
          else
            raise "Found multiple matching batch objects with identifier #{id}"            
          end
        else
          found_object = BatchObject.where("identifier = ?", id).order("updated_at asc").last
        end
        pid = found_object.pid if found_object
      end
    end
    return pid
  end
  
  # should be private?
  def explicit_relationship_pid(relationship_name)
    pid = nil
    if object_hash[relationship_name]
      if object_hash[relationship_name].is_a?(String)
        pid = object_hash[relationship_name]
      else
        pid = object_hash[relationship_name][PID]
      end
    end
    pid = manifest.relationship_pid(relationship_name) unless pid
    return pid
  end
  
  # should be private?
  def relationship_autoidlength(relationship_name)
    autoidlength = nil
    if object_hash[relationship_name]
      if object_hash[relationship_name].is_a?(Hash)
        autoidlength = object_hash[relationship_name][AUTOIDLENGTH]
      end
    end
    autoidlength = manifest.relationship_autoidlength(relationship_name) unless autoidlength
    return autoidlength
  end
  
  # should be private?
  def relationship_id(relationship_name)
    id = nil
    if object_hash[relationship_name]
      if object_hash[relationship_name].is_a?(Hash)
        id = object_hash[relationship_name][ID]
      end
    end
    id = manifest.relationship_id(relationship_name) unless id
    return id
  end
  
  # should be private?
  def relationship_batchid(relationship_name)
    batchid = nil
    if object_hash[relationship_name]
      if object_hash[relationship_name].is_a?(Hash)
        batchid = object_hash[relationship_name][BATCHID]
      end
    end
    batchid = manifest.relationship_batchid(relationship_name) unless batchid
    return batchid
  end
end