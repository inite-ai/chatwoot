module Enterprise::Concerns::User
  extend ActiveSupport::Concern

  included do
    has_many :captain_responses, class_name: 'Captain::AssistantResponse', dependent: :nullify, as: :documentable
    has_many :copilot_threads, dependent: :destroy_async
  end
end
