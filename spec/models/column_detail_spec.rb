require 'spec_helper'

describe ColumnDetail do
  describe "Associations" do
    it { should belong_to(:data_file) }
  end

  describe "Validation" do
    it { should validate_presence_of(:data_file_id) }
    it { should validate_presence_of(:name) }
  end

  describe "Scopes" do
    it "should return things in position order by default" do
      c1 = Factory(:column_detail, :position => 12)
      c2 = Factory(:column_detail, :position => 3)
      c3 = Factory(:column_detail, :position => 5)
      ColumnDetail.pluck(:id).should eq([c2.id, c3.id, c1.id])
    end
  end

  describe "Connected Mappings" do
    it "should return matching column mapping if it exists" do
      mapping = Factory(:column_mapping, :code => "test", :name => "My Mapping")
      Factory(:column_detail, :name => "test").get_mapped_name.should eq("My Mapping")
      Factory(:column_detail, :name => "Test").get_mapped_name.should eq("My Mapping")
    end
    it "should return nil if no mapping exists" do
      column = Factory(:column_detail, :name => "test")
      column.get_mapped_name.should eq(nil)
    end
  end
end
