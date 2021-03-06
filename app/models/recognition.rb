class Recognition < ActiveRecord::Base
  belongs_to :compliment, :foreign_key => :recognition_id
  belongs_to :reward, :foreign_key => :recognition_id
  belongs_to :user_accomplishment, :foreign_key => :recognition_id

  validates_presence_of :recognition_id, :recognition_type_id
  validates_uniqueness_of :recognition_id, :scope => [:recognition_type_id]

  before_create :set_url_token
  before_create :set_public_url

  @@recognition_type_compliment_id = RecognitionType.COMPLIMENT.id
  @@recognition_type_reward_id = RecognitionType.REWARD.id
  @@recognition_type_accomplishment_id = RecognitionType.ACCOMPLISHMENT.id

  def set_url_token
    generate_token('url_token')
  end

  def set_public_url
    begin
      url = "http://#{ENV['SITE_DOMAIN']}/recognitions/#{self.url_token}"
      self.public_url = TinyUrl.tiny_url(url)
    rescue => e
      logger.warn "#{e} You have attempted to shorten an invalid URI - #{url}"
    end
  end

  def generate_token(column)
    begin
      logger.info("Generate Token: #{column}")
      self[column] = SecureRandom.urlsafe_base64
    end while Recognition.exists?(column => self[column])
  end

  def self.create_from_user_accomplishment(ua)
    create(:recognition_type_id => RecognitionType.ACCOMPLISHMENT.id,
           :recognition_id => ua.id)
  end

  def self.create_from_compliment(compliment)
    create(:recognition_type_id => RecognitionType.COMPLIMENT.id,
           :recognition_id => compliment.id)
  end

  def self.create_from_reward(reward)
    create(:recognition_type_id => RecognitionType.REWARD.id,
           :recognition_id => reward.id)
  end

  def self.find_by_type_and_id(recognition_type_id, recognition_id)
    where(:recognition_type_id => recognition_type_id,
          :recognition_id => recognition_id).first
  end

  def is_compliment?
    self.recognition_type_id == @@recognition_type_compliment_id
    # self.recognition_type_id == RecognitionType.COMPLIMENT.id
  end

  def is_reward?
    self.recognition_type_id == @@recognition_type_reward_id
    # self.recognition_type_id == RecognitionType.REWARD.id
  end

  def is_accomplishment?
    self.recognition_type_id == @@recognition_type_accomplishment_id
    # self.recognition_type_id == RecognitionType.ACCOMPLISHMENT.id
  end

end
