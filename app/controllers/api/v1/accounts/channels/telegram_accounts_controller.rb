class Api::V1::Accounts::Channels::TelegramAccountsController < Api::V1::Accounts::BaseController
  before_action :fetch_telegram_account, only: [:show, :update, :destroy, :send_code, :verify_code, :verify_password]
  before_action :authorize_request, only: [:create, :update, :destroy]

  def create
    # Найти существующую запись или создать новую
    @telegram_account = Current.account.channel_telegram_accounts.find_or_initialize_by(
      phone_number: telegram_account_params[:phone_number]
    )
    
    # Обновляем атрибуты (для существующих записей или новых)
    @telegram_account.assign_attributes(telegram_account_params)
    
    if @telegram_account.save
      status = @telegram_account.previously_new_record? ? 'created' : 'updated'
      render json: { 
        id: @telegram_account.id,
        phone_number: @telegram_account.phone_number,
        status: status,
        requires_code: true
      }
    else
      render json: { errors: @telegram_account.errors }, status: :unprocessable_entity
    end
  end

  def show
    render json: {
      id: @telegram_account.id,
      phone_number: @telegram_account.phone_number,
      account_name: @telegram_account.account_name,
      is_active: @telegram_account.is_active,
      session_active: @telegram_account.active_session?
    }
  end

  def send_code
    # Use MTProto implementation
    result = @telegram_account.send_auth_code

    if result[:success]
      render json: { 
        message: 'MTProto code sent successfully',
        phone_code_hash: result[:phone_code_hash]
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def verify_code
    # Use MTProto implementation
    result = @telegram_account.authenticate_with_code(params[:code])

    if result[:success]
      # Создаем inbox если авторизация успешна
      create_inbox_for_account if @telegram_account.active_session?
      
      render json: { 
        message: 'Authentication successful',
        account_name: @telegram_account.account_name,
        inbox_id: @telegram_account.inbox&.id
      }
    else
      render json: { 
        error: result[:error],
        requires_password: result[:requires_password]
      }, status: :unprocessable_entity
    end
  end

  def verify_password
    service = TelegramAccount::AuthenticationService.new(channel: @telegram_account)
    result = service.authenticate_with_password(params[:password])

    if result[:success]
      # Создаем inbox если авторизация успешна
      create_inbox_for_account if @telegram_account.active_session?
      
      render json: { 
        message: 'Authentication successful',
        account_name: @telegram_account.account_name,
        inbox_id: @telegram_account.inbox&.id
      }
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def destroy
    @telegram_account.destroy
    head :ok
  end

  private

  def authorize_request
    authorize ::Inbox
  end

  def fetch_telegram_account
    @telegram_account = Current.account.channel_telegram_accounts.find(params[:id])
  end

  def telegram_account_params
    params.require(:telegram_account).permit(:app_id, :app_hash, :phone_number)
  end

  def create_inbox_for_account
    return if @telegram_account.inbox.present?

    inbox = Current.account.inboxes.create!(
      name: "Telegram Account (#{@telegram_account.account_name || @telegram_account.phone_number})",
      channel: @telegram_account
    )

    @telegram_account.start_polling
  end
end
