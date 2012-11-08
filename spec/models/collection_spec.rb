require 'spec_helper'

describe Collection do

  before do
    @collection = Collection.create
  end

  after do
    @collection.delete
  end

  it "should have a DC datastream" do
    @collection.datastreams["DC"].should be_kind_of ActiveFedora::Datastream
  end

  it "should have a RELS-EXT datastream" do
    @collection.datastreams["RELS-EXT"].should be_kind_of ActiveFedora::RelsExtDatastream
  end

  it "should have a rightsMetadata datastream" do
    @collection.datastreams["rightsMetadata"].should be_kind_of Hydra::Datastream::RightsMetadata
  end

  it "should be able to retrieve the item" do
    c = Collection.find(@collection.pid)
    c.pid.should eq(@collection.pid)
  end


end