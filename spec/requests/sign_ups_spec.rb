require 'spec_helper'

describe "SignUps" do
  
  before(:each) do
    u = FactoryGirl.create(:founder)
    visit new_shell_path
    fill_in "Email", :with => u.email
    fill_in "Password", :with => u.password
    click_button('Submit')
  end
  
  describe "GET '/signup'" do
    it "should be success" do
      visit '/signup'
      current_path.should == signup_path
    end
    
    it "should sign up a user and skip to display the users profile page" do
      visit signup_path
      fill_in "Email", :with => "test_user@complimentkarma.com"
      fill_in "Full Name", :with => "test user mcgee"
      fill_in "Password", :with => "1234 on the floor"
      click_button('Sign Up Free')
      page.should have_selector('title', :content => "Profile")
    end
  end
  
  describe "Send invitations to coworkers" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      visit login_path
      fill_in "Email", :with => @user.email
      fill_in "password", :with => @user.password
      click_button ("Log In")
      page.should have_selector('title', :content => "Profile")
    end
    
    # it "should send an invitation to a 'I work with' coworker no domain" do
    #   visit invite_coworkers_path
    #   fill_in "multi_invitation_email1", :with => "my_coworker"
    #   click_button
    #   i = Invitation.last
    #   i.invite_email.should eq("my_coworker@#{@user.domain}")
    #   i.from_email.should eq(@user.email)
    #   last_email.to.should include(i.invite_email)
    #   last_email.from.should include('no-reply@complimentkarma.com')
    # end
    
    # it "should send an invitation to a 'I work with' coworker with domain" do
    #   visit invite_coworkers_path
    #   fill_in "multi_invitation_email1", :with => "my_coworker@google.com"
    #   click_button
    #   i = Invitation.last
    #   i.invite_email.should eq("my_coworker@google.com")
    #   i.from_email.should eq(@user.email)
    #   last_email.to.should include(i.invite_email)
    #   last_email.from.should include('no-reply@complimentkarma.com')
    # end
    
    # it "should not send an invitation to a 'I work with' coworker with invalid email" do
    #   visit invite_coworkers_path
    #   fill_in "multi_invitation_email1", :with => "my coworker"
    #   click_button
    #   i = Invitation.last
    #   i.should be_nil
    # end
    
    # it "should send an invitation to a 'I manage' no domain" do
    #   visit invite_coworkers_path
    #   fill_in "multi_invitation_email1", :with => "my_employee"
    #   click_button
    #   i = Invitation.last
    #   i.invite_email.should eq("my_employee@#{@user.domain}")
    #   i.from_email.should eq(@user.email)
    #   last_email.to.should include(i.invite_email)
    #   last_email.from.should include('no-reply@complimentkarma.com')
    # end
  end
    
  describe "Send Invitations to others" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      visit login_path
      fill_in "Email", :with => @user.email
      fill_in "password", :with => @user.password
      click_button 'Log In'
      page.should have_selector('title', :content => "Profile")
    end
    
    # it "should send an invitation to other no domain" do
    #   visit invite_others_path
    #   fill_in "multi_invitation_email1", :with => "my_coworker"
    #   click_button
    #   i = Invitation.last
    #   i.invite_email.should eq("my_coworker@#{@user.domain}")
    #   i.from_email.should eq(@user.email)
    #   last_email.to.should include(i.invite_email)
    #   last_email.from.should include('no-reply@complimentkarma.com')
    # end
    
    # it "should send an invitation to other with domain" do
    #   visit invite_others_path
    #   fill_in "multi_invitation_email1", :with => "my_coworker@google.com"
    #   click_button
    #   i = Invitation.last
    #   i.invite_email.should eq("my_coworker@google.com")
    #   i.from_email.should eq(@user.email)
    #   last_email.to.should include(i.invite_email)
    #   last_email.from.should include('no-reply@complimentkarma.com')
    # end
    
    # it "should not send an invitation to other with invalid email" do
    #   visit invite_others_path
    #   fill_in "multi_invitation_email1", :with => "my coworker"
    #   click_button
    #   i = Invitation.last
    #   i.should be_nil
    # end
    
  end
  
  describe "sign up confirmation success" do
    let(:user2) { FactoryGirl.create(:user2) }

    before(:each) do
      visit signup_path
      fill_in "Email", :with => "test_user@complimentkarma.com"
      fill_in "Full Name", :with => "test user mcgee"
      fill_in "Password", :with => "1234 on the floor"
      click_button 'Sign Up Free'
      page.should have_selector('title', :content => "Profile")
      @user = User.last
    end
    
    it "should have confirmation link" do
      page.should have_selector('a', :content => "Resend Link")
    end
    
    it "should remove the resend link from the profile" do
      # user = User.last
      visit new_account_confirmation_url(:confirm_id => @user.new_account_confirmation_token)
      page.should have_selector('title', :content => 'Account Confirmation')
      # click_link 'profile'
      user = User.find(@user.id)
      fill_in "Email", :with => user.email
      fill_in "Password", :with => user.password
      click_button ("Log In")
      user.account_status.should eq(AccountStatus.CONFIRMED)
      page.should have_selector('title', :content => "Profile")
      response.should_not have_selector('a', :content => "Resend Link")
    end

    it "should update the compliment status with user confirmation" do
      @user.account_status.should eq(AccountStatus.UNCONFIRMED)
      c_pre = Compliment.create(:sender_email => user2.email,
                        :receiver_email => @user.email,
                        :skill_id => Skill.last.id,
                        :compliment_type_id => ComplimentType.PERSONAL_TO_PERSONAL.id,
                        :comment => 'Testing')
      c_pre.compliment_status.should eq(ComplimentStatus.PENDING_RECEIVER_CONFIRMATION)
      user = User.find(@user.id)
      visit new_account_confirmation_url(:confirm_id => user.new_account_confirmation_token)
      page.should have_selector('title', :content => 'Account Confirmation')
      # click_link 'profile'
      # page.should have_selector('title', :content => "Profile")
      # response.should_not have_selector('a', :content => "Resend Link")
      # user = User.last
      user.reload
      fill_in "Email", :with => user.email
      fill_in "Password", :with => user.password
      click_button ("Log In")
      user.account_status.should eq(AccountStatus.CONFIRMED)
      c_post = Compliment.find(c_pre.id)
      c_post.compliment_status.should eq(ComplimentStatus.ACTIVE)
    end

    it "should attach pending compliments to new users" do
      email = "test_x_user@complimentkarma.com"
      c_pre = Compliment.create(:sender_email => user2.email,
                        :receiver_email => email,
                        :skill_id => Skill.last.id,
                        :compliment_type_id => ComplimentType.PERSONAL_TO_PERSONAL.id,
                        :comment => 'Testing')
      c_pre.compliment_status.should eq(ComplimentStatus.PENDING_RECEIVER_REGISTRATION)
      visit signup_path
      fill_in "Email", :with => email
      fill_in "Full Name", :with => "test user jones"
      fill_in "Password", :with => "1234 on the floor"
      click_button 'Sign Up Free'
      u = User.find_by_email(email)
      u.should_not be_nil
      u.compliments_received.count.should == 1
      c = u.compliments_received.first
      c.compliment_status.should eq(ComplimentStatus.PENDING_RECEIVER_CONFIRMATION)
      c.tags.count.should == 2
      c.tags.first.group.should be_social
    end

    it "should mark all emails as confirmed" do
      @user.email_addresses.count.should == 1
    end
    
  end

  describe "sign up confirmation failure" do 
    it "should not confirm the user when using an invalid token" do
      bad_token = 'vFZgbwWT_aUJ6BGcowwJ3A'
      visit new_account_confirmation_url(:confirm_id => bad_token)
      current_path.should == root_path
    end
  end
  
end
