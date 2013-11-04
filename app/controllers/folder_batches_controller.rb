class FolderBatchesController < ApplicationController

  def new  
  end
  
  def create
    @folder_batch = DulHydra::Batch::Models::FolderBatch.new(params[:folder_batch])
  end
  
end