class User < ActiveRecord::Base
  belongs_to :account_status
  has_many :user_rewards
  has_many :rewards, :through => :user_rewards
  has_many :user_accomplishments
  has_many :accomplishments, :through => :user_accomplishments
  has_many :ck_likes
  
  attr_accessor :password
  # use attr_accessible to white list vars that can be mass assigned
  attr_accessible :name, :email, :password, :password_confirmation, :photo,
                  :first_name, :middle_name, :last_name, :domain, :job_title,
                  :account_status_id, :account_status, :address_line_1, :address_line_2, 
                  :city, :state_cd, :zip_cd, :profile_url, :profile_headline, 
                  :industry_id
  
  has_attached_file  :photo, 
                     :styles => { :mini => "40x40>",
                                  :thumb => "60x60>",
                                  :small => "150x150>",
                                  :medium => "300x300>" },
                     :convert_options => { :all => '-auto-orient' },
                     :storage => :s3,
                     :s3_credentials => "#{Rails.root.to_s}/config/s3.yml",
                     :path => "/:id/:style/:filename"
                     
  email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  
  validates :name, :presence => true,
                   :length => { :maximum => 50 },
                   :on => :create
  validates :email, :presence => true,
                    :format => { :with => email_regex },
                    :uniqueness => { :case_sensitive => false },
                    :on => :create
  validates :password, :presence => true,
                       :length => { :within => 6..40 },
                       :on => :create

  before_create :encrypt_password
  before_create :set_name
  before_create :set_domain
  before_create :set_account_status
  after_create :associate_received_compliments
  after_create :associate_sent_compliments
  after_create :create_relationships
  
  # Return true if the user's password matches the submitted password
  def has_password?(submitted_password)
    encrypted_password == encrypt(submitted_password)
  end
  
  def self.authenticate(email, submitted_password)
    user = find_by_email(email)
    (user && user.has_password?(submitted_password)) ? user : nil
  end
  
  def self.authenticate_with_salt(id, cookie_salt)
    user = find_by_id(id)
    (user && user.salt == cookie_salt) ? user : nil
  end
  
  def self.authenticate_founder(email, submitted_password)
    user = find_by_email(email)
    logger.info("User: #{user.name} | #{user.email} | #{user.founder}") if user
    (user && 
     user.founder &&
     user.has_password?(submitted_password)) ? user : nil
  end
  
  def self.authenticate_founder_with_salt(id, cookie_salt)
    user = find_by_id(id)
    (user && 
     user.founder &&
     user.salt == cookie_salt) ? user : nil
  end
  
  def send_password_reset
    generate_token(:password_reset_token)
    self.password_reset_sent_at = Time.zone.now
    save!
    UserMailer.password_reset(self).deliver
  end
  
  def generate_token(column)
    begin
      logger.info("Generate Token: #{column}")
      self[column] = SecureRandom.urlsafe_base64
    end while User.exists?(column => self[column])
  end
  
  def set_name
    name_array = self.name.split(' ')
    if name_array.size == 1
      self.first_name = name_array[0].capitalize
    elsif name_array.size == 2
      self.first_name = name_array[0].capitalize
      self.last_name = name_array[1].capitalize
    elsif name_array.size > 2
      self.first_name = name_array[0].capitalize
      self.middle_name = name_array[1].capitalize
      self.last_name = name_array[2].capitalize
    end    
  end
  
  def full_name
    name = []
    name << self.first_name if self.first_name
    name << self.middle_name if self.middle_name
    name << self.last_name if self.last_name
    return name.join(' ')
  end
  
  def first_last_initial
    l = self.last_name[0].capitalize if self.last_name
    return "#{self.first_name} #{l}"
  end
  
  def set_domain
    domain_array = self.email.split('@')
    self.domain = domain_array.last
  end
  
  def send_account_confirmation
    generate_token(:new_account_confirmation_token)
    save!
    UserMailer.account_confirmation(self).deliver
  end
  
  def set_account_status
    self.account_status = AccountStatus.UNCONFIRMED if self.account_status.nil?
  end
      
  def encrypt_password
    self.salt = BCrypt::Engine.generate_salt
    self.encrypted_password = BCrypt::Engine.hash_secret(password, salt)
  end
  
  def self.get_account_status(email)
    u = User.find_by_email(email)
    if u
      return u.account_status
    else
      return nil
    end
  end
  
  def self.is_internal?(user_1_id, user_2_id)    
    user_1 = User.find(user_1_id)
    user_2 = User.find(user_2_id)
    return user_1 && user_2 && user_1.domain == user_2.domain
  end
  
  def associate_received_compliments
    my_received_compliments = Compliment.where('receiver_email = ? AND receiver_user_id is null', self.email)
    my_received_compliments.each do |c|
      c.receiver_user_id = self.id
      c.compliment_status =  update_receiver_status(c.compliment_status)
      c.save
      UpdateHistory.Received_Compliment(c)
    end
  end
  
  def associate_sent_compliments
    my_sent_compliments = Compliment.where('sender_email = ? AND sender_user_id is null', self.email)
    my_sent_compliments.each do |c|
      c.sender_user_id = self.id
      c.compliment_status =  update_sender_status(c.compliment_status)
    end
  end
  
  def create_relationships
    received_compliments = Compliment.find_all_by_receiver_user_id(self.id)
    received_compliments.each do |compliment|
      Relationship.create(:user_1_id => compliment.sender_user_id,
                          :user_2_id => compliment.receiver_user_id)
    end
  end
  
  # Updates the status one level for the receiver
  # registration -> confirmation
  # confirmation -> active
  def update_receiver_status(compliment_status)
    case compliment_status
    when ComplimentStatus.PENDING_RECEIVER_CONFIRMATION
      return ComplimentStatus.ACTIVE
    when ComplimentStatus.PENDING_RECEIVER_REGISTRATION
      return ComplimentStatus.PENDING_RECEIVER_CONFIRMATION
    when ComplimentStatus.PENDING_SENDER_REGISTRATION
      return ComplimentStatus.PENDING_SENDER_REGISTRATION
    else
      return nil
    end
  end
  
  def update_sender_status(compliment_status)
    case compliment_status
    when ComplimentStatus.PENDING_RECEIVER_CONFIRMATION
      return ComplimentStatus.PENDING_RECEIVER_CONFIRMATION
    when ComplimentStatus.PENDING_RECEIVER_REGISTRATION
      return ComplimentStatus.PENDING_RECEIVER_REGISTRATION
    else
      return nil
    end
  end

  def confirmed?
    self.account_status.id == AccountStatus.CONFIRMED.id
  end
  
  private
    def encrypt(password)
      BCrypt::Engine.hash_secret(password, self.salt)
    end
    
end
