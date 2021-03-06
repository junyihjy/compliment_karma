module PrivacyHelper

	# is the group a super group of the subject group 
	# (i.e. does it live in the subject_groups super_group_relationships)
	def super_group?(group, subject_group)
		# public_group = Group.get_public_group(subject_group.group_owner)
		super_group_relationship_ids = subject_group.super_group_relationships.collect{|sgr| sgr.super_group_id }
		logger.info("Super Group IDS: #{super_group_relationship_ids}")
		return true if super_group_relationship_ids.include?(group.id) #|| 
									 # super_group_relationship_ids.include?(public_group.id)
		return false
	end

	def super_group_list(ref_group)
		a = ref_group.super_group_relationships.sort{|x,y| x.super_group.sort_order <=> y.super_group.sort_order}
		a = a.keep_if{|sgr| display_group_in_visibility_list(ref_group, sgr.super_group) }
		sg = a.collect{|sgr| sgr.super_group.name}
		return sg.join(', ')
	end

	def display_group_in_visibility_list(ref_group, group)
		if ref_group.professional? || ref_group.social?
			if group.only_me? || group.declined?
				return false
			else
				return true
			end
		else
			return true
		end

	end

end