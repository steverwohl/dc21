class ColumnMapping < ActiveRecord::Base

  validates_presence_of :code
  validates_presence_of :name
  validates_uniqueness_of :code, :case_sensitive => false

  default_scope :order => 'name ASC'

  def self.code_to_name_map
    Hash[*all.collect { |cm| [cm.code, cm.name] }.flatten]
  end

  def self.map_names_to_codes(names)
    codes = []
    names.each do |name|
      mappings = ColumnMapping.find_all_by_name(name)
      if mappings.empty?
        codes << name
      else
        mappings.each { |mapping| codes << mapping.code }
      end
    end
    codes
  end

  def check_col_mapping(name)
    if self.code.to_s.downcase == name.to_s.downcase
      return self
    end
  end

  def check_code_exists?(mappings)
    mappings.each do |existing_map|
      if self.code.to_s.downcase == existing_map.code.to_s.downcase && existing_map.code!="" && self!=existing_map
        return true
      end
    end
    return false
  end

end
