class ComplimentType < ActiveRecord::Base
  has_many :compliments
  
  validates_uniqueness_of :name
  default_scope :order => "id ASC"
  
# Change the Compliment Type drop down options to following (Preserve the upper/lowercase, exactly as i entered below):
# - from my PROFESSIONAL to receiver’s PROFESSIONAL profile
# - from my PROFESSIONAL to receiver’s SOCIAL profile
# - from my SOCIAL to receiver’s PROFESSIONAL profile
# - from my SOCIAL to receiver’s SOCIAL profile

  def self.PROFESSIONAL_TO_PROFESSIONAL
    find_by_name("Professional to Professional") || 
    find_by_name("from my PROFESSIONAL to receivers PROFESSIONAL profile")
  end
  
  def self.PROFESSIONAL_TO_PERSONAL
    find_by_name("Professional to Personal") || 
    find_by_name("from my PROFESSIONAL to receivers SOCIAL profile")
  end
  
  def self.PERSONAL_TO_PROFESSIONAL
    find_by_name("Personal to Professional") || 
    find_by_name("from my SOCIAL to receivers PROFESSIONAL profile")
  end
  
  def self.PERSONAL_TO_PERSONAL
    find_by_name("Personal to Personal") || 
    find_by_name("from my SOCIAL to receivers SOCIAL profile")
  end

  def self.is_professional?(compliment_type_id)
    return compliment_type_id == ComplimentType.PROFESSIONAL_TO_PROFESSIONAL.id ||
           compliment_type_id == ComplimentType.PROFESSIONAL_TO_PERSONAL.id
  end

  def self.professional_send_ids
    return [
      self.PROFESSIONAL_TO_PROFESSIONAL.id, 
      self.PROFESSIONAL_TO_PERSONAL.id
    ]
  end

  def self.professional_receive_ids
    return [
      self.PROFESSIONAL_TO_PROFESSIONAL.id,
      self.PERSONAL_TO_PROFESSIONAL.id
    ]
  end

  def self.social_send_ids
    return [
      self.PERSONAL_TO_PROFESSIONAL.id,
      self.PERSONAL_TO_PERSONAL.id
    ]
  end

  def self.social_receive_ids
    return [
      self.PROFESSIONAL_TO_PERSONAL.id,
      self.PERSONAL_TO_PERSONAL.id
    ]
  end

  def self.compliment_type_list(sender_is_a_company, receiver_is_a_company)
    logger.info("Sender is a company: #{sender_is_a_company} \n" +
                "Receiver is a company: #{receiver_is_a_company}")
    compliment_types = []
    if sender_is_a_company.to_s == "true" && receiver_is_a_company.to_s == "true"
      compliment_types = [ComplimentType.PROFESSIONAL_TO_PROFESSIONAL]
    elsif sender_is_a_company.to_s == "true"
      compliment_types = [ComplimentType.PROFESSIONAL_TO_PROFESSIONAL,
                           ComplimentType.PROFESSIONAL_TO_PERSONAL]
    elsif receiver_is_a_company.to_s == "true"
      compliment_types = [ComplimentType.PROFESSIONAL_TO_PROFESSIONAL,
                           ComplimentType.PERSONAL_TO_PROFESSIONAL]
    else
      compliment_types = ComplimentType.all
    end
    return compliment_types
  end

  def self.auto_assign(compliment)
    sender = compliment.sender
    receiver = compliment.receiver
    if sender && receiver
      if sender.on_whitelist? && receiver.on_whitelist?
        return ComplimentType.PROFESSIONAL_TO_PROFESSIONAL.id
      elsif sender.on_whitelist?
        return ComplimentType.PROFESSIONAL_TO_PERSONAL.id
      elsif receiver.on_whitelist?
        return ComplimentType.PERSONAL_TO_PROFESSIONAL.id
      else
        return ComplimentType.PERSONAL_TO_PERSONAL.id
      end
    else
      if sender.on_whitelist?
        return ComplimentType.PROFESSIONAL_TO_PERSONAL.id
      else
        return ComplimentType.PERSONAL_TO_PERSONAL.id
      end
    end
  end

end
