# frozen_string_literal: true

module Charges
  module Validators
    class GraduatedService < Charges::Validators::BaseService
      def valid?
        if ranges.blank?
          add_error(field: :ranges, error_code: 'missing_graduated_range')
        else
          next_from_value = 0
          ranges.each_with_index do |range, index|
            validate_amounts(range)

            unless valid_bounds?(range, index, next_from_value)
              add_error(field: :ranges, error_code: 'invalid_graduated_ranges')
            end

            next_from_value = (range[:to_value] || 0) + 1
          end
        end

        super
      end

      private

      def ranges
        charge.properties.map(&:with_indifferent_access)
      end

      def validate_amounts(range)
        unless ::Validators::DecimalAmountService.new(range[:per_unit_amount]).valid_amount?
          add_error(field: :per_unit_amount, error_code: 'invalid_amount')
        end

        return if ::Validators::DecimalAmountService.new(range[:flat_amount]).valid_amount?

        add_error(field: :flat_amount, error_code: 'invalid_amount')
      end

      def valid_bounds?(range, index, next_from_value)
        range[:from_value] == (next_from_value) && (
          index == (ranges.size - 1) && range[:to_value].nil? ||
          index < (ranges.size - 1) && (range[:to_value] || 0) > range[:from_value]
        )
      end
    end
  end
end
