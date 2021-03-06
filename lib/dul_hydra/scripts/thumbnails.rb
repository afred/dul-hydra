module DulHydra::Scripts
  class Thumbnails
    
    def initialize(collection_pid)
      begin
        @collection = Collection.find(collection_pid, :cast => true)
      rescue ActiveFedora::ObjectNotFound
        puts "Could not find #{collection_pid}"
      end
    end
    
    def execute
      items_solr = @collection.items.load_from_solr
      items_solr.each do |item_solr|
        item = ActiveFedora::Base.find(item_solr["id"], :cast => true)
        unless item.has_thumbnail?
          component = item.first_child
          if component.has_thumbnail?
            item.thumbnail.content = component.thumbnail.content
            item.thumbnail.mimeType = component.thumbnail.mimeType
            item.save
          end
        end
      end
      item = @collection.first_child
      if item.has_thumbnail?
        @collection.thumbnail.content = item.thumbnail.content
        @collection.thumbnail.mimeType = item.thumbnail.mimeType
        @collection.save
      end
    end
    
    def collection
      @collection
    end
  end
end