# -*- encoding : utf-8 -*-

require 'json'

class SolrDocument 

  include Blacklight::Solr::Document

  # self.unique_key = 'id'
  
  # The following shows how to setup this blacklight document to display marc documents
  # extension_parameters[:marc_source_field] = :marc_display
  # extension_parameters[:marc_format_type] = :marcxml
  # use_extension( Blacklight::Solr::Document::Marc) do |document|
  #   document.key?( :marc_display  )
  # end
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )

  #
  # Custom methods
  #

  def object_profile
    JSON.parse(self[:object_profile_display].first)
  end

  def datastreams
    object_profile["datastreams"]
  end

  def admin_policy?
    !admin_policy_uri.nil?
  end

  def admin_policy_uri
    get(:is_governed_by_s)
  end

  def admin_policy_pid
    uri = admin_policy_uri
    uri &&= ActiveFedora::Base.pids_from_uris(uri)
  end

  def parent?
    !parent_uri.nil?
  end

  def parent_uri
    get(:is_part_of_s) || get(:is_member_of_s) || get(:is_member_of_collection_s)
  end

  def parent_pid
    uri = parent_uri
    uri &&= ActiveFedora::Base.pids_from_uris(uri)
  end

end
