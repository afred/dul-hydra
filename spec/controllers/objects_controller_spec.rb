require 'spec_helper'

describe ObjectsController do
  let(:object) { FactoryGirl.create(:test_model) }
  let(:user) { FactoryGirl.create(:user) }
  before do 
    sign_in user 
  end
  after(:all) { user.delete }
  after(:each) { object.delete }
  context "#show" do
    before do
      # XXX Should be able to do this, but it doesn't work as expected:
      # controller.current_ability.can(:read, ActiveFedora::Base) { |obj| obj.pid == object.pid }
      controller.current_ability.stub(:test_read).with(object.pid).and_return(true)
      get :show, :id => object
    end
    it "should render the show template" do
      response.should render_template(:show)
    end
  end
  context "#edit" do
    before do
      controller.current_ability.can(:edit, ActiveFedora::Base) { |obj| obj.pid == object.pid }
      get :edit, :id => object
    end
    it "should render the hydra-editor edit template" do
      response.should render_template('records/edit')
    end
  end
  context "#update" do
    before do
      controller.current_ability.can(:update, ActiveFedora::Base) { |obj| obj.pid == object.pid }
      put :update, :id => object, :test_model => {:title => "Updated"}
    end
    it "should redirect to the show page" do
      response.should redirect_to(descriptive_metadata_path(object))
    end
    it "should update the object" do
      object.reload
      object.title.should == ["Updated"]
    end
  end
  context "#upload" do
    it "should write the uploaded file to the `content' datastream"
    it "should redirect to the show page"
  end
end
