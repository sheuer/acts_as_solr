require File.dirname(__FILE__) + '/../spec_helper'

describe ActsAsSolr::ParserMethods do
  describe "#field_name_to_solr_field" do
    describe "(with stubs)" do
      before(:each) do
        Book.should respond_to(:configuration) # safe stub!
        Book.stub!(:configuration).and_return(
          :solr_fields => [
            [:id,     {:type => :integer}],
            [:title,  {:type => :string}],
            ["title", {:type => :text}], # chuck in a string
            [:title,  {:type => :sort}],
            [:created_at, {:type => :date}],
          ])
      end
    
      it "should return a normalised field" do
        rtn = Book.send(:field_name_to_solr_field, "title")
        rtn.should == [:title, {:type => :string}]
      end
      
      it "should accept a string field_name" do
        rtn = Book.send(:field_name_to_solr_field, "id")
        rtn.should == [:id, {:type => :integer}]
      end
      
      it "should accept a symbol field_name" do
        rtn = Book.send(:field_name_to_solr_field, :id)
        rtn.should == [:id, {:type => :integer}]
      end
    
      it "should return the first matching :solr_fields entry by default" do
        rtn = Book.send(:field_name_to_solr_field, "title")
        rtn.should == [:title, {:type => :string}]
      end
      
      it "should match a favoured_type first" do
        rtn = Book.send(:field_name_to_solr_field, "title", :sort)
        rtn.should == [:title, {:type => :sort}]
      end
      
      it "should ingore a nil favoured_type" do
        rtn = Book.send(:field_name_to_solr_field, "title", nil)
        rtn.should == [:title, {:type => :string}]
      end
      
      it "should match multiple favoured types" do
        rtn = Book.send(:field_name_to_solr_field, "title", [:sort, :date])
        rtn.should == [:title, {:type => :sort}]
      end
      
      it "should ignore an absent favoured type" do
        rtn = Book.send(:field_name_to_solr_field, "title", :not_here)
        rtn.should == [:title, {:type => :string}]
      end
      
      it "should ignore multiple absent favoured types" do
        rtn = Book.send(:field_name_to_solr_field, "title", [:date, :integer, :are, :unmatched])
        rtn.should == [:title, {:type => :string}]
      end
      
      it "should return nil for no match" do
        Book.send(:field_name_to_solr_field, "no_field").should == nil
      end
    end
    
    describe "(without stubs)" do
      it "should return a normalised field" do
        rtn = Book.send(:field_name_to_solr_field, "name")
        rtn.should == [:name, {:type => :text}]
      end
    end
  end
  
  describe "#solr_field_to_lucene_field" do  
    it "should return a string" do
      rtn = Book.send(:solr_field_to_lucene_field, [:title, {:type => :string}])
      rtn.should == "title_s"
    end
    
    [[:sort, "sort"], [:string, "s"], [:text, "t"]].each do |field_type, suffix|
      it "should handle #{field_type.inspect} fields" do
        rtn = Book.send(:solr_field_to_lucene_field, [:fieldy, {:type => field_type}])
        rtn.should == "fieldy_#{suffix}"
      end
    end
  end
  
  describe "#field_name_to_lucene_field" do
    it "should conjoin fn-sf and sf-lf" do
      Book.should_receive(:field_name_to_solr_field).with("some", :input).and_return("join")
      Book.should_receive(:solr_field_to_lucene_field).with("join").and_return("together")
      
      Book.send(:field_name_to_lucene_field, "some", :input).should == "together"
    end
    
    it "should return just the field name if there is no matching solr_field" do
      Book.should_receive(:field_name_to_solr_field).with("some", :input).and_return(nil)
      Book.should_receive(:solr_field_to_lucene_field).exactly(0).times
      
      Book.send(:field_name_to_lucene_field, "some", :input).should == "some"
    end
  end
end