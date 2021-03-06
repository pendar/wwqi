class Translation < ActiveRecord::Base
  # pagination code
  cattr_reader :per_page
  @@per_page = 1000

  validates_uniqueness_of :key, :scope => :locale
  
end
