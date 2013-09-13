require 'spec_helper'

module DulHydra::Scripts
  
  shared_examples "a successful conversion" do
    before { @actual_xml = File.open(output) { |f| Nokogiri::XML(f) } }
    it "should produce xml that matches the expected xml" do
      expect(@actual_xml).to be_equivalent_to(expected_xml)
    end
  end
  
  shared_examples "a successful split conversion" do
    let(:actual_xml) { [] }
    let(:outputs) do      
      outs = []
      Dir.foreach(output) do |f|
        puts File.join(output, f)
        outs << File.join(output, f) if File.extname(f).eql?(".xml")
      end
      outs
    end
    before do
      outputs.each do |output|
        puts output
        actual_xml << File.open(output) { |f| Nokogiri::XML(f) }
      end
    end
    it "should produce xml that matches the expected xml for each output file" do
      actual_xml.each_index do |index|
        puts index
        expect(actual_xml[index]).to be_equivalent_to(expected_xml[index])
      end
    end
  end
  
  describe "CsvToXml" do
    
    let(:test_dir) { Dir.mktmpdir("dul_hydra_test") }
    
    after { FileUtils.remove_dir test_dir }
    
    context "simple conversion" do

      let(:output) { File.join(test_dir, 'simple.xml') }
      let(:script) { DulHydra::Scripts::CsvToXml.new(:csv => input, :xml => output, :profile => profile) }
      let(:expected) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'simple.xml') }
      let(:expected_xml) { File.open(expected) { |f| Nokogiri::XML(f) } }
      before { script.execute }
      
      context "csv input file" do
        let(:input) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'simple.csv') }
        let(:profile) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'simple.yml') }
        it_behaves_like "a successful conversion"
      end
    
      context "tabbed input file" do
        let(:input) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'tabbed.txt') }
        let(:profile) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'tabbed.yml') }
        it_behaves_like "a successful conversion"      
      end
      
    end
    
    context "CONTENTdm conversion" do
      let(:input) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm.txt') }
      before { script.execute }

      context "no schema" do
        let(:script) { DulHydra::Scripts::CsvToXml.new(:csv => input, :xml => output, :profile => profile) }
        context "no split" do
          let(:output) { File.join(test_dir, 'contentdm.xml') }
          let(:profile) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm.yml') }
          let(:expected) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm.xml') }
          let(:expected_xml) { File.open(expected) { |f| Nokogiri::XML(f) } }
          it_behaves_like "a successful conversion"
        end
        context "split" do
          let(:output) { File.join(test_dir, 'outputs') }
          let(:profile) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm_split.yml') }
          let(:expected) do
            [ File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm1.xml'),
            File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm2.xml') ]
          end
          let(:expected_xml) do
            exps = []
            expected.each { |exp| exps << File.open(exp) { |f| Nokogiri::XML(f) } }
            exps
          end
          it_behaves_like "a successful split conversion"          
        end          
      end
      
      context "Hydra qualified Dublin Core schema" do
        let(:script) { DulHydra::Scripts::CsvToXml.new(:csv => input, :xml => output, :profile => profile, :schema_map => schema) }
        let(:output) { File.join(test_dir, 'outputs') }
        let(:profile) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm_split.yml') }
        let(:schema) { File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm2qdc.yml') }
        let(:expected) do
          [ File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm1_qdc.xml'),
          File.join(Rails.root, 'spec', 'fixtures', 'csv_processing', 'contentdm2_qdc.xml') ]
        end
        let(:expected_xml) do
          exps = []
          expected.each { |exp| exps << File.open(exp) { |f| Nokogiri::XML(f) } }
          exps
        end
        it_behaves_like "a successful split conversion"          
        
      end
      
    end
    
  end
  
end