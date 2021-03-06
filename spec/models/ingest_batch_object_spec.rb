require 'spec_helper'

module DulHydra::Batch::Models

  shared_examples "a valid object" do
    it "should be valid" do
      expect(object.validate).to be_empty
    end
  end
  
  shared_examples "an invalid object" do
    it "should not be valid" do
      expect(object.validate).to include(error_message)
    end
  end
  
  shared_examples "a successful ingest" do
    let(:results) { object.process }
    it "should result in a verified repository object" do
      expect(results.repository_object).to_not be_nil
      expect(results.verified).to be_true
      results.verifications.each { |condition, result| expect(result).to eq(BatchObject::VERIFICATION_PASS) }
      expect(object.pid).to eq(results.repository_object.pid)
      expect(object.verified).to be_true
    end
  end
  
  describe IngestBatchObject do
    
    context "validate" do
    
      context "valid object" do
        after do
          object.batch_object_relationships.each do |r|
            ActiveFedora::Base.find(r[:object], :cast => true).destroy if r[:name].eql?("parent")
            AdminPolicy.find(r[:object]).destroy if r[:name].eql?("admin_policy")
            Collection.find(r.object).destroy if r.name.eql?("collection")
          end
        end
        context "generic object" do
          let(:object) { FactoryGirl.create(:generic_ingest_batch_object) }
          it_behaves_like "a valid object"
        end
        context "target object" do
          let(:object) { FactoryGirl.create(:target_ingest_batch_object) }
          it_behaves_like "a valid object"
        end
      end
  
      context "invalid object" do
        let(:error_prefix) { "#{object.identifier} [Database ID: #{object.id}]:"}
        context "missing model" do
          let(:object) { FactoryGirl.create(:ingest_batch_object) }
          let(:error_message) { "#{error_prefix} Model required for INGEST operation" }
          it_behaves_like "an invalid object"
        end
        context "invalid model" do
          let(:object) { FactoryGirl.create(:ingest_batch_object) }
          let(:error_message) { "#{error_prefix} Invalid model name: #{object.model}" }
          before { object.model = "BadModel" }
          it_behaves_like "an invalid object"
        end
        context "invalid admin policy" do
          let(:object) { FactoryGirl.create(:ingest_batch_object, :has_model) }
          context "admin policy pid object does not exist" do
            let(:admin_policy_pid) { "bogus:AdminPolicy" }
            let(:error_message) { "#{error_prefix} admin_policy relationship object does not exist: #{admin_policy_pid}" }
            before do
              relationship = FactoryGirl.create(:batch_object_add_relationship, :name => "admin_policy", :object => admin_policy_pid, :object_type => BatchObjectRelationship::OBJECT_TYPE_PID)
              object.batch_object_relationships << relationship
              object.save
            end
            it_behaves_like "an invalid object"
          end
          context "admin policy pid object exists but is not admin policy" do
            let(:error_message) { "#{error_prefix} admin_policy relationship object #{@not_admin_policy.pid} exists but is not a(n) AdminPolicy" }
            before do
              @not_admin_policy = FactoryGirl.create(:test_model)
              relationship = FactoryGirl.create(:batch_object_add_relationship, :name => "admin_policy", :object => @not_admin_policy.pid, :object_type => BatchObjectRelationship::OBJECT_TYPE_PID)
              object.batch_object_relationships << relationship
              object.save
            end
            after { @not_admin_policy.destroy }
            it_behaves_like "an invalid object"
          end
        end
        context "invalid datastreams" do
          let(:object) { FactoryGirl.create(:ingest_batch_object, :has_model, :with_add_datastreams) }
          context "invalid datastream name" do
            let(:error_message) { "#{error_prefix} Invalid datastream name for #{object.model}: #{object.batch_object_datastreams.first[:name]}" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.name = "invalid_name"
              datastream.save!
            end
            it_behaves_like "an invalid object"
          end
          context "invalid payload type" do
            let(:error_message) { "#{error_prefix} Invalid payload type for #{object.batch_object_datastreams.first[:name]} datastream: #{object.batch_object_datastreams.first[:payload_type]}" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.payload_type = "invalid_type"
              datastream.save!
            end
            it_behaves_like "an invalid object"
          end
          context "missing data file" do
            let(:error_message) { "#{error_prefix} Missing or unreadable file for #{object.batch_object_datastreams.last[:name]} datastream: #{object.batch_object_datastreams.last[:payload]}" }
            before do
              datastream = object.batch_object_datastreams.last
              datastream.payload = "non_existent_file.xml"
              datastream.save!
            end
            it_behaves_like "an invalid object"
          end
          context "checksum without checksum type" do
            let(:error_message) { "#{error_prefix} Must specify checksum type if providing checksum for #{object.batch_object_datastreams.first.name} datastream" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.checksum = "123456"
              datastream.checksum_type = nil
              datastream.save!
            end
            it_behaves_like "an invalid object"
          end
          context "invalid checksum type" do
            let(:error_message) { "#{error_prefix} Invalid checksum type for #{object.batch_object_datastreams.first.name} datastream: #{object.batch_object_datastreams.first.checksum_type}" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.checksum_type = "SHA-INVALID"
              datastream.save!
            end
            it_behaves_like "an invalid object"
          end
        end
        context "invalid parent" do
          let(:object) { FactoryGirl.create(:ingest_batch_object, :has_model) }
          context "parent pid object does not exist" do
            let(:parent_pid) { "bogus:TestParent" }
            let(:error_message) { "#{error_prefix} parent relationship object does not exist: #{parent_pid}" }
            before do
              relationship = FactoryGirl.create(:batch_object_add_relationship, :name => "parent", :object => parent_pid, :object_type => BatchObjectRelationship::OBJECT_TYPE_PID)
              object.batch_object_relationships << relationship
              object.save
            end
            it_behaves_like "an invalid object"
          end
          context "parent pid object exists but is not correct parent object type" do
            let(:error_message) { "#{error_prefix} parent relationship object #{@not_parent.pid} exists but is not a(n) TestParent" }
            before do
              @not_parent = FactoryGirl.create(:test_model)
              relationship = FactoryGirl.create(:batch_object_add_relationship, :name => "parent", :object => @not_parent.pid, :object_type => BatchObjectRelationship::OBJECT_TYPE_PID)
              object.batch_object_relationships << relationship
              object.save
            end
            after { @not_parent.destroy }
            it_behaves_like "an invalid object"
          end
        end
        context "invalid target_for" do
          let(:object) { FactoryGirl.create(:ingest_batch_object) }
          context "target_for pid object does not exist" do
            let(:collection_pid) { "bogus:Collection" }
            let(:error_message) { "#{error_prefix} collection relationship object does not exist: #{collection_pid}" }
            before do
              object.model = "Target"
              relationship = FactoryGirl.create(:batch_object_add_relationship, :name => "collection", :object => collection_pid, :object_type => BatchObjectRelationship::OBJECT_TYPE_PID)
              object.batch_object_relationships << relationship
              object.save
            end
            it_behaves_like "an invalid object"
          end
          context "target_for pid object exists but is not collection" do
            let(:error_message) { "#{error_prefix} collection relationship object #{@not_collection.pid} exists but is not a(n) Collection" }
            before do
              @not_collection = FactoryGirl.create(:test_model)
              object.model = "Target"
              relationship = FactoryGirl.create(:batch_object_add_relationship, :name => "collection", :object => @not_collection.pid, :object_type => BatchObjectRelationship::OBJECT_TYPE_PID)
              object.batch_object_relationships << relationship
              object.save
            end
            after { @not_collection.destroy }
            it_behaves_like "an invalid object"
          end
        end
      end
    end
  
    context "ingest" do
      
      context "successful ingest" do
        after do
          object.batch_object_relationships.each do |r|
            ActiveFedora::Base.find(r[:object], :cast => true).destroy if r[:name].eql?("parent")
            AdminPolicy.find(r[:object]).destroy if r[:name].eql?("admin_policy")
            Collection.find(r.object).destroy if r.name.eql?("collection")
          end
          ActiveFedora::Base.find(object.pid, :cast => true).destroy
        end
        context "generic object" do
          let(:object) { FactoryGirl.create(:generic_ingest_batch_object) }
          it_behaves_like "a successful ingest"
        end
      end
      
    end
      
  end

end