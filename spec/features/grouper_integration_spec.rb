require 'spec_helper'
require 'dul_hydra'

Warden.test_mode!

describe "Grouper integration" do
  let(:user) { FactoryGirl.create(:user) }
  let(:object) { FactoryGirl.create(:collection) }
  before do
    object.title = "Grouper Works!"
    object.read_groups = ["duke:library:repository:ddr:foo:bar"]
    object.save!
    Warden.on_next_request do |proxy|
      proxy.env[DulHydra.remote_groups_env_key] = "urn:mace:duke.edu:groups:library:repository:ddr:foo:bar"
      proxy.set_user user
    end
  end
  after do
    object.delete
    user.delete
    Warden.test_reset!
  end
  it "should honor Grouper group access control" do
    visit object_path(object)
    page.should have_content("Grouper Works!")
  end
  
end
