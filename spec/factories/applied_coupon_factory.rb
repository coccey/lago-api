FactoryBot.define do
  factory :applied_coupon do
    customer
    coupon

    amount_cents { 200 }
    amount_currency { 'EUR' }
    status { 'active' }
  end
end
