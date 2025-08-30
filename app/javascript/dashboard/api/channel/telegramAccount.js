/* global axios */
import ApiClient from '../ApiClient';

class TelegramAccountAPI extends ApiClient {
  constructor() {
    super('channels/telegram_accounts', { accountScoped: true });
  }

  create(params) {
    return axios.post(this.url, { telegram_account: params });
  }

  sendCode(accountId) {
    return axios.post(`${this.url}/${accountId}/send_code`);
  }

  verifyCode(accountId, code) {
    return axios.post(`${this.url}/${accountId}/verify_code`, { code });
  }

  verifyPassword(accountId, password) {
    return axios.post(`${this.url}/${accountId}/verify_password`, { password });
  }
}

export default new TelegramAccountAPI();
