class PermissionsController < ApplicationController

  include DulHydra::Controller::ObjectsControllerBehavior

  layout 'objects'

  before_filter :authorize_action!

  def edit
  end

  def update
    redirect_action = params[:continue].present? ? :permissions_edit_path : :permissions_path
    redirect_to send(redirect_action, params[:id])
  end

  protected

  def authorize_action!
    authorize! params[:action].to_sym, params[:id]
  end

end
