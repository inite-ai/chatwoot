<script setup>
import { ref, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useMapGetter } from 'dashboard/composables/store';

const uiFlags = useMapGetter('inboxes/getUIFlags');

// Состояние формы
const step = ref('credentials'); // credentials, code, password, success
const formData = ref({
  appId: '',
  appHash: '',
  phoneNumber: '',
  code: '',
  password: '',
});

const telegramAccountId = ref(null);
const requiresPassword = ref(false);
const phoneCodeHash = ref('');
const errorMessage = ref('');

// Валидация
const rules = computed(() => {
  const baseRules = {
    appId: { required },
    appHash: { required },
    phoneNumber: { required },
  };

  if (step.value === 'code') {
    baseRules.code = { required };
  }

  if (step.value === 'password') {
    baseRules.password = { required };
  }

  return baseRules;
});

const v$ = useVuelidate(rules, formData);

// Методы API
const sendCode = async () => {
  try {
    const response = await window.axios.post(
      `/api/v1/accounts/current/channels/telegram_accounts/${telegramAccountId.value}/send_code`
    );

    step.value = 'code';
    phoneCodeHash.value = response.data.phone_code_hash;
    requiresPassword.value = response.data.requires_password;
    useAlert('Authentication code sent to your phone');
  } catch (error) {
    const sendCodeErrorMessage =
      error.response?.data?.error ||
      error.message ||
      'Failed to send authentication code';
    useAlert(sendCodeErrorMessage);
  }
};

const redirectToAgents = inboxId => {
  router.replace({
    name: 'settings_inboxes_add_agents',
    params: {
      page: 'new',
      inbox_id: inboxId,
    },
  });
};

const createTelegramAccount = async () => {
  try {
    const response = await window.axios.post(
      '/api/v1/accounts/current/channels/telegram_accounts',
      {
        telegram_account: {
          app_id: formData.value.appId,
          app_hash: formData.value.appHash,
          phone_number: formData.value.phoneNumber,
        },
      }
    );

    telegramAccountId.value = response.data.id;
    await sendCode();
  } catch (error) {
    const createAccountErrorMessage =
      error.response?.data?.errors ||
      error.message ||
      'Failed to create Telegram account';
    useAlert(createAccountErrorMessage);
  }
};

const verifyCode = async () => {
  try {
    const response = await window.axios.post(
      `/api/v1/accounts/current/channels/telegram_accounts/${telegramAccountId.value}/verify_code`,
      {
        code: formData.value.code,
      }
    );

    if (response.data.requires_password) {
      step.value = 'password';
    } else {
      redirectToAgents(response.data.inbox_id);
    }
  } catch (error) {
    errorMessage.value =
      error.response?.data?.error ||
      error.message ||
      'Code verification failed';
    if (error.response?.data?.requires_password) {
      step.value = 'password';
    }
  }
};

const verifyPassword = async () => {
  try {
    const response = await window.axios.post(
      `/api/v1/accounts/current/channels/telegram_accounts/${telegramAccountId.value}/verify_password`,
      {
        password: formData.value.password,
      }
    );

    redirectToAgents(response.data.inbox_id);
  } catch (error) {
    errorMessage.value =
      error.response?.data?.error ||
      error.message ||
      'Password verification failed';
  }
};

// Обработчики форм
const handleCredentialsSubmit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    return;
  }

  await createTelegramAccount();
};

const handleCodeSubmit = async () => {
  v$.value.$touch();
  if (v$.value.code.$invalid) {
    return;
  }

  await verifyCode();
};

const handlePasswordSubmit = async () => {
  v$.value.$touch();
  if (v$.value.password.$invalid) {
    return;
  }

  await verifyPassword();
};
</script>

<template>
  <div
    class="border border-n-weak bg-n-solid-1 rounded-t-lg border-b-0 h-full w-full p-6 col-span-6 overflow-auto"
  >
    <!-- Шаг 1: Credentials -->
    <div v-if="step === 'credentials'">
      <PageHeader
        :header-title="$t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.TITLE')"
        :header-content="$t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.DESC')"
      />

      <form
        class="flex flex-wrap flex-col mx-0"
        @submit.prevent="handleCredentialsSubmit"
      >
        <div class="flex-shrink-0 flex-grow-0 mb-4">
          <label :class="{ error: v$.appId.$error }">
            {{ $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.APP_ID.LABEL') }}
            <input
              v-model="formData.appId"
              type="text"
              :placeholder="
                $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.APP_ID.PLACEHOLDER')
              "
              @blur="v$.appId.$touch"
            />
          </label>
          <p class="help-text">
            {{ $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.APP_ID.SUBTITLE') }}
          </p>
        </div>

        <div class="flex-shrink-0 flex-grow-0 mb-4">
          <label :class="{ error: v$.appHash.$error }">
            {{ $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.APP_HASH.LABEL') }}
            <input
              v-model="formData.appHash"
              type="text"
              :placeholder="
                $t(
                  'INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.APP_HASH.PLACEHOLDER'
                )
              "
              @blur="v$.appHash.$touch"
            />
          </label>
          <p class="help-text">
            {{
              $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.APP_HASH.SUBTITLE')
            }}
          </p>
        </div>

        <div class="flex-shrink-0 flex-grow-0 mb-4">
          <label :class="{ error: v$.phoneNumber.$error }">
            {{
              $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PHONE_NUMBER.LABEL')
            }}
            <input
              v-model="formData.phoneNumber"
              type="tel"
              :placeholder="
                $t(
                  'INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PHONE_NUMBER.PLACEHOLDER'
                )
              "
              @blur="v$.phoneNumber.$touch"
            />
          </label>
          <p class="help-text">
            {{
              $t(
                'INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PHONE_NUMBER.SUBTITLE'
              )
            }}
          </p>
        </div>

        <div class="w-full mt-4">
          <NextButton
            :is-loading="uiFlags.isCreating"
            type="submit"
            solid
            blue
            :label="
              $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.SEND_CODE_BUTTON')
            "
          />
        </div>
      </form>
    </div>

    <!-- Шаг 2: Verification Code -->
    <div v-else-if="step === 'code'">
      <PageHeader
        :header-title="
          $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.CODE_VERIFICATION.TITLE')
        "
        :header-content="
          $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.CODE_VERIFICATION.DESC')
        "
      />

      <form
        class="flex flex-wrap flex-col mx-0"
        @submit.prevent="handleCodeSubmit"
      >
        <div class="flex-shrink-0 flex-grow-0 mb-4">
          <label :class="{ error: v$.code.$error }">
            {{ $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.CODE.LABEL') }}
            <input
              v-model="formData.code"
              type="text"
              maxlength="5"
              :placeholder="
                $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.CODE.PLACEHOLDER')
              "
              @blur="v$.code.$touch"
            />
          </label>
          <p class="help-text">
            {{ $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.CODE.SUBTITLE') }}
          </p>
        </div>

        <div v-if="errorMessage" class="text-red-500 mb-4">
          {{ errorMessage }}
        </div>

        <div class="w-full mt-4">
          <NextButton
            :is-loading="uiFlags.isCreating"
            type="submit"
            solid
            blue
            :label="
              $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.VERIFY_CODE_BUTTON')
            "
          />
        </div>
      </form>
    </div>

    <!-- Шаг 3: Password (2FA) -->
    <div v-else-if="step === 'password'">
      <PageHeader
        :header-title="
          $t(
            'INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PASSWORD_VERIFICATION.TITLE'
          )
        "
        :header-content="
          $t(
            'INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PASSWORD_VERIFICATION.DESC'
          )
        "
      />

      <form
        class="flex flex-wrap flex-col mx-0"
        @submit.prevent="handlePasswordSubmit"
      >
        <div class="flex-shrink-0 flex-grow-0 mb-4">
          <label :class="{ error: v$.password.$error }">
            {{ $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PASSWORD.LABEL') }}
            <input
              v-model="formData.password"
              type="password"
              :placeholder="
                $t(
                  'INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PASSWORD.PLACEHOLDER'
                )
              "
              @blur="v$.password.$touch"
            />
          </label>
          <p class="help-text">
            {{
              $t('INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.PASSWORD.SUBTITLE')
            }}
          </p>
        </div>

        <div v-if="errorMessage" class="text-red-500 mb-4">
          {{ errorMessage }}
        </div>

        <div class="w-full mt-4">
          <NextButton
            :is-loading="uiFlags.isCreating"
            type="submit"
            solid
            blue
            :label="
              $t(
                'INBOX_MGMT.ADD.TELEGRAM_ACCOUNT_CHANNEL.VERIFY_PASSWORD_BUTTON'
              )
            "
          />
        </div>
      </form>
    </div>
  </div>
</template>
