require 'spec_helper'

describe Manifest do
  
  context "load yaml manifest file" do
    let(:manifest) { Manifest.new(File.join(Rails.root, 'spec', 'fixtures', 'batch_ingest', 'miscellaneous', 'yaml.yml')) }
    let(:yaml_hash) { eval File.open(File.join(Rails.root, 'spec', 'fixtures', 'batch_ingest', 'miscellaneous', 'yaml_hash.txt')) { |f| f.read } }
    it "should lead the YAML file" do
      expect(manifest.manifest_hash).to be_a_kind_of(Hash)
      expect(manifest.manifest_hash).to eq(yaml_hash)
    end
  end
  
  context "methods" do
    let(:manifest) { Manifest.new }
    context "basepath, label, model" do
      let(:basepath) { "basePath" }
      let(:label) { "expectedLabel" }
      let(:model) { "modelToUse" }
      before { manifest.manifest_hash = HashWithIndifferentAccess.new("basepath" => basepath, "label" => label, "model" => model) }
      it "should return the correct basepath, label, and model" do
        expect(manifest.basepath).to eq(basepath)
        expect(manifest.label).to eq(label)
        expect(manifest.model).to eq(model)
      end
    end
    context "batch" do
      after { manifest.batch.destroy }
      context "new batch" do
        let(:batch_name) { "New Batch Name #{Time.now.to_s}" }
        let(:batch_description) { "New Batch Description #{Time.now.to_s}" }
        before { manifest.manifest_hash = HashWithIndifferentAccess.new("batch" => { "name" => batch_name, "description" => batch_description } ) }
        it "should create a new batch object" do
          expect(manifest.batch.name).to eq(batch_name)
          expect(manifest.batch.description).to eq(batch_description)
        end
      end
      context "existing batch" do
        let(:batch_name) { "Existing Batch Name #{Time.now.to_s}" }
        let(:batch_description) { "Existing Batch Description #{Time.now.to_s}" }
        before do
          @batch = Batch.create(:name => batch_name, :description => batch_description)
          manifest.manifest_hash = HashWithIndifferentAccess.new("batch" => { "id" => @batch.id })
        end
        it "should use the existing batch object" do
          expect(manifest.batch.name).to eq(batch_name)
          expect(manifest.batch.description).to eq(batch_description)
        end
      end
    end
    context "checksums" do
      context "identifier element, node xpath, type, type xpath, value xpath" do
        context "provided" do
          let(:identifier_element) { "identifierElement" }
          let(:node_xpath) { "/node/xpath" }
          let(:type) { "FOO-1" }
          let(:type_xpath) { "the_type" }
          let(:value_xpath) { "the_value" }
          before do
            manifest.manifest_hash = HashWithIndifferentAccess.new("checksum" => { "identifier_element" =>  identifier_element,
                                                                                 "node_xpath" => node_xpath,
                                                                                 "type" => type,
                                                                                 "type_xpath" => type_xpath,
                                                                                 "value_xpath" => value_xpath
                                                                               } )
          end
          it "should use the provided values" do
            expect(manifest.checksum_identifier_element).to eq(identifier_element)
            expect(manifest.checksum_node_xpath).to eq(node_xpath)
            expect(manifest.checksum_type?).to be_true
            expect(manifest.checksum_type).to eq(type)
            expect(manifest.checksum_type_xpath).to eq(type_xpath)
            expect(manifest.checksum_value_xpath).to eq(value_xpath)
          end
        end
        context "not provided" do
          it "should use the default values if any" do
            expect(manifest.checksum_identifier_element).to eq("id")
            expect(manifest.checksum_node_xpath).to eq("/checksums/checksum")
            expect(manifest.checksum_type?).to be_false
            expect(manifest.checksum_type).to be_nil
            expect(manifest.checksum_type_xpath).to eq("type")
            expect(manifest.checksum_value_xpath).to eq("value")
          end
        end
      end
      context "checksums XML document" do
        let(:checksums_filepath) { File.join(Rails.root, 'spec', 'fixtures', 'batch_ingest', 'miscellaneous', 'checksums.xml') }
        let(:checksums_document) { File.open(checksums_filepath) { |f| Nokogiri.XML(f) } }
        before { manifest.manifest_hash = HashWithIndifferentAccess.new("checksum" => { "location" => checksums_filepath }) }
        it "should open the XML document" do
          expect(manifest.checksums?).to be_true
          expect(manifest.checksums).to be_equivalent_to(checksums_document)
        end
      end
    end
    context "datastreams" do
      context "datastreams list" do
        let(:datastream_names) { [ "DS1", "DS2", "DS3" ] }
        before { manifest.manifest_hash = HashWithIndifferentAccess.new("datastreams" => datastream_names) }
        it "should return the list of datastream names" do
          expect(manifest.datastreams.size).to eq(datastream_names.size)
          manifest.datastreams.each { |datastream| expect(datastream_names).to include(datastream) }
        end
      end
      context "datastream extension, datastream location" do
        let(:datastream_name) { "fooDatastream" }
        let(:extension) { ".foo" }
        let(:location) { "/tmp" }
        context "provided" do
          before { manifest.manifest_hash = HashWithIndifferentAccess.new(datastream_name => { "extension" => extension, "location" => location }) }
          it "should use the provided values" do
            expect(manifest.datastream_extension(datastream_name)).to eq(extension)
            expect(manifest.datastream_location(datastream_name)).to eq(location)     
          end
        end
        context "not provided" do
          it "should return nil" do
            expect(manifest.datastream_extension(datastream_name)).to be_nil
            expect(manifest.datastream_location(datastream_name)).to be_nil
          end
        end
      end
    end
    context "objects" do
      let(:object1) { HashWithIndifferentAccess.new( "identifier" => "id001" ) }
      let(:object2) { HashWithIndifferentAccess.new( "identifier" => "id002" ) }
      let(:object3) { HashWithIndifferentAccess.new( "identifier" => "id003" ) }
      let(:objects) { [ object1, object2, object3 ] }
      before { manifest.manifest_hash = HashWithIndifferentAccess.new( "objects" => objects ) }
      it "should return manifest objects" do
        expect(manifest.objects.size).to eq(objects.size)
        manifest.objects.each { |obj| expect(["id001", "id002", "id003"]).to include(obj.key_identifier) }
      end
    end
    context "relationships" do
      context "relationship autoidlength, relationship id, relationship pid" do
        let(:relationship_name) { "foo_relationship" }
        let(:autoidlength) { 5 }
        let(:id) { "id123" }
        let(:pid) { "foo:1234" }
        context "provided" do
          before { manifest.manifest_hash = HashWithIndifferentAccess.new(relationship_name => { "autoidlength" => autoidlength, "id" => id, "pid" => pid }) }
          it "should use the provided values" do
            expect(manifest.relationship_autoidlength(relationship_name)).to eq(autoidlength)
            expect(manifest.relationship_id(relationship_name)).to eq(id)
            expect(manifest.relationship_pid(relationship_name)).to eq(pid)
          end
        end
        context "not provided" do
          it "should return nil" do
            expect(manifest.relationship_autoidlength(relationship_name)).to be_nil
            expect(manifest.relationship_id(relationship_name)).to be_nil
            expect(manifest.relationship_pid(relationship_name)).to be_nil
          end
        end
      end
    end
  end
  
end