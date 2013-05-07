module FcrepoAdmin
  class ObjectsController < CatalogController
    include FcrepoAdmin::Controller::ObjectsControllerBehavior

    include DulHydra::SolrHelper

    def preservation_events
      self.solr_search_params_logic += [:preservation_events_filter]
      @title = params[:object_id]
      @response, @document_list = get_search_results
    end
    
  end
end
