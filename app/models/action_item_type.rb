class ActionItemType < ActiveRecord::Base
	has_many :action_items

	validates_uniqueness_of :name

	def self.Authorize_Contact
		find_by_name('Authorize Compliment')
	end
	
end
