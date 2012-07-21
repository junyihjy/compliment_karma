require 'spec_helper'

describe "SignUps" do
  
  before(:each) do
    u = FactoryGirl.create(:founder)
    visit new_shell_path
    fill_in "Email", :with => u.email
    fill_in "Password", :with => u.password
    click_button
  end
  
  describe "GET '/signup'" do
    it "should be success" do
      get '/signup'
      response.should be_success
    end
    
    it "should sign up a user and display the invite coworkers page" do
      visit signup_path
      fill_in "Email", :with => "test_user@example.com"
      fill_in "Full Name", :with => "test user mcgee"
      fill_in "Password", :with => "1234 on the floor"
      click_button
      response.should have_selector('title', :content => "Invite Coworkers")
    end
    
    it "should sign up a user and skip to display the invite others page" do
      visit signup_path
      fill_in "Email", :with => "test_user@example.com"
      fill_in "Full Name", :with => "test user mcgee"
      fill_in "Password", :with => "1234 on the floor"
      click_button
      response.should have_selector('title', :content => "Invite Coworkers")
      click_link "skip"
      response.should have_selector('title', :content => "Invite Others")
    end
    
    it "should sign up a user and skip to display the users profile page" do
      visit signup_path
      fill_in "Email", :with => "test_user@example.com"
      fill_in "Full Name", :with => "test user mcgee"
      fill_in "Password", :with => "1234 on the floor"
      click_button
      response.should have_selector('title', :content => "Invite Coworkers")
      click_link "skip"
      response.should have_selector('title', :content => "Invite Others")
      click_link "skip"
      response.should have_selector('title', :content => "Profile")
    end
  end
  
  describe "Send invitations to coworkers" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      visit login_path
      fill_in "Email", :with => @user.email
      fill_in "password", :with => @user.password
      click_button
      response.should have_selector('title', :content => "Profile")
    end
    
    it "should send an invitation to a 'I work with' coworker no domain" do
      visit invite_coworkers_path
      fill_in "multi_invitation_email1", :with => "my_coworker"
      click_button
      i = Invitation.last
      i.invite_email.should eq("my_coworker@#{@user.domain}")
      i.from_email.should eq(@user.email)
      last_email.to.should include(i.invite_email)
      last_email.from.should include('no-reply@complimentkarma.com')
    end
    
    it "should send an invitation to a 'I work with' coworker with domain" do
      visit invite_coworkers_path
      fill_in "multi_invitation_email1", :with => "my_coworker@google.com"
      click_button
      i = Invitation.last
      i.invite_email.should eq("my_coworker@google.com")
      i.from_email.should eq(@user.email)
      last_email.to.should include(i.invite_email)
      last_email.from.should include('no-reply@complimentkarma.com')
    end
    
    it "should not send an invitation to a 'I work with' coworker with invalid email" do
      visit invite_coworkers_path
      fill_in "multi_invitation_email1", :with => "my coworker"
      click_button
      i = Invitation.last
      i.should be_nil
    end
    
    it "should send an invitation to a 'I manage' no domain" do
      visit invite_coworkers_path
      fill_in "multi_invitation_email1", :with => "my_employee"
      click_button
      i = Invitation.last
      i.invite_email.should eq("my_employee@#{@user.domain}")
      i.from_email.should eq(@user.email)
      last_email.to.should include(i.invite_email)
      last_email.from.should include('no-reply@complimentkarma.com')
    end
  end
    
  describe "Send Invitations to others" do
    before(:each) do
      @user = FactoryGirl.create(:user)
      visit login_path
      fill_in "Email", :with => @user.email
      fill_in "password", :with => @user.password
      click_button
      response.should have_selector('title', :content => "Profile")
    end
    
    it "should send an invitation to other no domain" do
      visit invite_others_path
      fill_in "multi_invitation_email1", :with => "my_coworker"
      click_button
      i = Invitation.last
      i.invite_email.should eq("my_coworker@#{@user.domain}")
      i.from_email.should eq(@user.email)
      last_email.to.should include(i.invite_email)
      last_email.from.should include('no-reply@complimentkarma.com')
    end
    
    it "should send an invitation to other with domain" do
      visit invite_others_path
      fill_in "multi_invitation_email1", :with => "my_coworker@google.com"
      click_button
      i = Invitation.last
      i.invite_email.should eq("my_coworker@google.com")
      i.from_email.should eq(@user.email)
      last_email.to.should include(i.invite_email)
      last_email.from.should include('no-reply@complimentkarma.com')
    end
    
    it "should not send an invitation to other with invalid email" do
      visit invite_others_path
      fill_in "multi_invitation_email1", :with => "my coworker"
      click_button
      i = Invitation.last
      i.should be_nil
    end
    
  end
  
  describe "sign up confirmation" do
    before(:each) do
      visit signup_path
      fill_in "Email", :with => "test_user@example.com"
      fill_in "Full Name", :with => "test user mcgee"
      fill_in "Password", :with => "1234 on the floor"
      click_button
      click_link "skip" # Invite Coworkers
      click_link "skip" # Invite Others
      response.should have_selector('title', :content => "Profile")
      @user = User.last
    end
    
    it "should have confirmation link" do
      response.should have_selector('a', :content => "Resend Link")
    end
    
    it "should remove the resend link from the profile" do
      user = User.last
      visit new_account_confirmation_url(user.new_account_confirmation_token)
      response.should have_selector('title', :content => 'Account Confirmation')
      click_link 'profile'
      # user.account_status.should eq(AccountStatus.CONFIRMED)
      response.should have_selector('title', :content => "Profile")
      response.should_not have_selector('a', :content => "Resend Link")
    end
    
  end
  
end
