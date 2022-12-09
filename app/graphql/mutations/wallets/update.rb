# frozen_string_literal: true

module Mutations
  module Wallets
    class Update < BaseMutation
      include AuthenticableApiUser
      include RequiredOrganization

      graphql_name 'UpdateCustomerWallet'
      description 'Updates a new Customer Wallet'

      argument :id, ID, required: true
      argument :name, String, required: false
      argument :expiration_at, GraphQL::Types::ISO8601DateTime, required: false

      # NOTE: Legacy fields, will be removed when releasing the timezone feature
      argument :expiration_date, GraphQL::Types::ISO8601Date, required: false

      type Types::Wallets::Object

      def resolve(**args)
        wallet = context[:current_user].wallets.find_by(id: args[:id])

        result = ::Wallets::UpdateService
          .new(context[:current_user])
          .update(
            wallet: wallet,
            args: WalletLegacyInput.new(
              wallet&.organization,
              args,
            ).update_input,
          )

        result.success? ? result.wallet : result_error(result)
      end
    end
  end
end
