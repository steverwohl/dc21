class UsersController < ApplicationController

  before_filter :authenticate_user!
  load_and_authorize_resource
  set_tab :admin
  layout 'admin'

  def index
    @users = User.deactivated_or_approved
    set_tab :users, :contentnavigation
  end

  def show
    if @user.pending_approval?
      set_tab :accessrequests, :contentnavigation
    else
      set_tab :users, :contentnavigation
    end
  end

  def access_requests
    @users = User.pending_approval
    set_tab :accessrequests, :contentnavigation
  end

  def add_access_group_to
    group_id = params[:user][:access_groups]
    if group_id.blank?
      redirect_to(user_path(@user), :alert => "Please select an access group to add.")
    else
      @user.addToAccessGroup(group_id)
      if @user.save
        redirect_to(@user, :notice => "The user is added to the access group #{AccessGroup.find_by_id(group_id).name} successfully")
      end
    end
  end

  def remove_access_group_from
    group_id = params[:group_id]
    group = AccessGroup.find_by_id(group_id)
    if group.primary_user == @user
      redirect_to(@user, :alert => "#{@user.full_name} is the primary user for group #{group.name}, please nominate an alternative primary user before attempting to remove them.")
    else
      @user.remove_from_access_group(group_id)
      if @user.save
        redirect_to(@user)
      end
    end
  end

  def deactivate
    if !@user.check_number_of_superusers(params[:id], current_user.id) 
      redirect_to(@user, :alert => "You cannot deactivate this account as it is the only account with Administrator privileges.")
    else
      @user.deactivate
      redirect_to(@user, :notice => "The user has been deactivated.")
    end
  end

  def activate
    @user.activate
    redirect_to(@user, :notice => "The user has been activated.")
  end

  def reject
    @user.reject_access_request
    @user.destroy
    redirect_to(access_requests_users_path, :notice => "The access request for #{@user.email} was rejected.")
  end

  def reject_as_spam
    @user.reject_access_request
    redirect_to(access_requests_users_path, :notice => "The access request for #{@user.email} was rejected and this email address will be permanently blocked.")
  end

  def edit_role
    set_tab :users, :contentnavigation
    if @user == current_user
      flash.now[:alert] = "You are changing the role of the user you are logged in as."
    elsif @user.rejected?
      redirect_to(users_path, :alert => "Role can not be set. This user has previously been rejected as a spammer.")
    end
    @roles = Role.by_name
  end

  def edit_approval
    set_tab :accessrequests, :contentnavigation
    @roles = Role.by_name
  end

  def update_role
    if params[:user][:role_id].blank?
        redirect_to(edit_role_user_path(@user), :alert => "Please select a role for the user.")
    else
      @user.role_id = params[:user][:role_id]
      if !@user.check_number_of_superusers(params[:id], current_user.id)
        redirect_to(edit_role_user_path(@user), :alert => "Only one superuser exists. You cannot change this role.")
      elsif @user.save
        redirect_to(@user, :notice => "The role for #{@user.email} was successfully updated.")
      end
    end
  end

  def approve
    if !params[:user][:role_id].blank?
      @user.role_id = params[:user][:role_id]
      @user.save
      @user.approve_access_request

      redirect_to(access_requests_users_path, :notice => "The access request for #{@user.email} was approved.")
    else
      redirect_to(edit_approval_user_path(@user), :alert => "Please select a role for the user.")
    end
  end

end
