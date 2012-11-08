module DulHydra::Models
  module Contentable
    extend ActiveSupport::Concern
    included do
      has_file_datastream :name => "content", :type => ActiveFedora::Datastream
    end
  end
end