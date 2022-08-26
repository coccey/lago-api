# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mutations::Plans::Update, type: :graphql do
  let(:membership) { create(:membership) }
  let(:organization) { membership.organization }
  let(:plan) { create(:plan, organization: organization) }
  let(:mutation) do
    <<~GQL
      mutation($input: UpdatePlanInput!) {
        updatePlan(input: $input) {
          id,
          name,
          code,
          interval,
          payInAdvance,
          amountCents,
          amountCurrency,
          charges {
            id,
            chargeModel,
            billableMetric { id name code },
            amount,
            freeUnits,
            packageSize,
            rate,
            fixedAmount,
            freeUnitsPerEvents,
            freeUnitsPerTotalAggregation,
            graduatedRanges { fromValue, toValue },
            volumeRanges { fromValue, toValue }
          }
        }
      }
    GQL
  end

  let(:billable_metrics) do
    create_list(:billable_metric, 5, organization: organization)
  end

  it 'updates a plan' do
    result = execute_graphql(
      current_user: membership.user,
      query: mutation,
      variables: {
        input: {
          id: plan.id,
          name: 'Updated plan',
          code: 'new_plan',
          interval: 'monthly',
          payInAdvance: false,
          amountCents: 200,
          amountCurrency: 'EUR',
          charges: [
            {
              billableMetricId: billable_metrics[0].id,
              amount: '100.00',
              chargeModel: 'standard',
            },
            {
              billableMetricId: billable_metrics[1].id,
              chargeModel: 'package',
              amount: '300.00',
              freeUnits: 10,
              packageSize: 10,
            },
            {
              billableMetricId: billable_metrics[2].id,
              chargeModel: 'percentage',
              rate: '0.25',
              fixedAmount: '2',
              freeUnitsPerEvents: 5,
              freeUnitsPerTotalAggregation: '50',
            },
            {
              billableMetricId: billable_metrics[3].id,
              chargeModel: 'graduated',
              graduatedRanges: [
                {
                  fromValue: 0,
                  toValue: 10,
                  perUnitAmount: '2.00',
                  flatAmount: '0',
                },
                {
                  fromValue: 11,
                  toValue: nil,
                  perUnitAmount: '3.00',
                  flatAmount: '3.00',
                },
              ],
            },
            {
              billableMetricId: billable_metrics[4].id,
              chargeModel: 'volume',
              volumeRanges: [
                {
                  fromValue: 0,
                  toValue: 10,
                  perUnitAmount: '2.00',
                  flatAmount: '0',
                },
                {
                  fromValue: 11,
                  toValue: nil,
                  perUnitAmount: '3.00',
                  flatAmount: '3.00',
                },
              ],
            },
          ],
        },
      },
    )

    result_data = result['data']['updatePlan']

    aggregate_failures do
      expect(result_data['id']).to be_present
      expect(result_data['name']).to eq('Updated plan')
      expect(result_data['code']).to eq('new_plan')
      expect(result_data['interval']).to eq('monthly')
      expect(result_data['payInAdvance']).to eq(false)
      expect(result_data['amountCents']).to eq(200)
      expect(result_data['amountCurrency']).to eq('EUR')
      expect(result_data['charges'].count).to eq(5)

      standard_charge = result_data['charges'][0]
      expect(standard_charge['amount']).to eq('100.00')
      expect(standard_charge['chargeModel']).to eq('standard')

      package_charge = result_data['charges'][1]
      expect(package_charge['chargeModel']).to eq('package')
      expect(package_charge['amount']).to eq('300.00')
      expect(package_charge['freeUnits']).to eq(10)
      expect(package_charge['packageSize']).to eq(10)

      percentage_charge = result_data['charges'][2]
      expect(percentage_charge['chargeModel']).to eq('percentage')
      expect(percentage_charge['rate']).to eq('0.25')
      expect(percentage_charge['fixedAmount']).to eq('2')
      expect(percentage_charge['freeUnitsPerEvents']).to eq(5)
      expect(percentage_charge['freeUnitsPerTotalAggregation']).to eq('50')

      graduated_charge = result_data['charges'][3]
      expect(graduated_charge['chargeModel']).to eq('graduated')
      expect(graduated_charge['graduatedRanges'].count).to eq(2)

      volume_charge = result_data['charges'][4]
      expect(volume_charge['chargeModel']).to eq('volume')
      expect(volume_charge['volumeRanges'].count).to eq(2)
    end
  end

  context 'without current user' do
    it 'returns an error' do
      result = execute_graphql(
        query: mutation,
        variables: {
          input: {
            id: plan.id,
            name: 'Updated plan',
            code: 'new_plan',
            interval: 'monthly',
            payInAdvance: false,
            amountCents: 200,
            amountCurrency: 'EUR',
            charges: [],
          },
        },
      )

      expect_unauthorized_error(result)
    end
  end
end
