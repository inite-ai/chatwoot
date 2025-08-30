module EnsureCurrentAccountHelper
  private

  def current_account
    @current_account ||= ensure_current_account
    Current.account = @current_account
  end

  def ensure_current_account
    account = resolve_account
    render_unauthorized('Account is suspended') and return unless account.active?

    if current_user
      account_accessible_for_user?(account)
    elsif @resource.is_a?(AgentBot)
      account_accessible_for_bot?(account)
    end
    account
  end

  def resolve_account
    if params[:account_id] == 'current'
      # For "current" account, find the user's default account or first accessible account
      return current_user.accounts.first if current_user
      
      # If no current_user (e.g., bot access), we can't resolve "current"
      raise ActiveRecord::RecordNotFound, "Cannot resolve 'current' account without authenticated user"
    else
      Account.find(params[:account_id])
    end
  end

  def account_accessible_for_user?(account)
    @current_account_user = account.account_users.find_by(user_id: current_user.id)
    Current.account_user = @current_account_user
    render_unauthorized('You are not authorized to access this account') unless @current_account_user
  end

  def account_accessible_for_bot?(account)
    render_unauthorized('Bot is not authorized to access this account') unless @resource.agent_bot_inboxes.find_by(account_id: account.id)
  end
end
