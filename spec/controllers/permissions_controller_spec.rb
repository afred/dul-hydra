require 'spec_helper'

describe PermissionsController do
  let(:object) { FactoryGirl.create(:test_model) }
  let(:user) { FactoryGirl.create(:user) }
  before do 
    sign_in user 
  end
  after(:all) { user.delete }
  after(:each) do
    object.delete
    sign_out user
  end
  describe "#edit" do
    it "should render the edit template" do
      controller.current_ability.can(:edit, String) do |obj|
        obj == object.pid
      end
      get :edit, :id => object
      response.should render_template(:edit)      
    end
  end
  describe "#update" do
    before do
      controller.current_ability.can(:update, String) do |obj|
        obj == object.pid
      end
    end
    it "should update the admin policy assignment"
    it "should update the permissions"
    context "`continue' param is present" do
      it "should redirect to the edit view" do
        put :update, :id => object, :continue => "1"
        response.should redirect_to(permissions_edit_path(object))
      end
    end
    context "`continue' param is not present" do
      it "should redirect to the show view" do
        put :update, :id => object
        response.should redirect_to(permissions_path(object))
      end
    end
  end
end
