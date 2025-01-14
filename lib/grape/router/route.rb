# frozen_string_literal: true

require 'grape/router/pattern'
require 'grape/router/attribute_translator'
require 'forwardable'

module Grape
  class Router
    class Route
      extend Forwardable

      attr_reader :app, :pattern, :options, :attributes
      attr_accessor :index

      def_delegators :pattern, :path, :origin
      delegate Grape::Router::AttributeTranslator::ROUTE_ATTRIBUTES => :attributes

      def initialize(method, pattern, **options)
        @options = options
        @pattern = Grape::Router::Pattern.new(pattern, **options)
        @attributes = Grape::Router::AttributeTranslator.new(**options, request_method: upcase_method(method))
      end

      def exec(env)
        @app.call(env)
      end

      def apply(app)
        @app = app
        self
      end

      def match?(input)
        return if input.blank?

        attributes.forward_match ? input.start_with?(pattern.origin) : pattern.match?(input)
      end

      def params(input = nil)
        return params_without_input if input.blank?

        parsed = pattern.params(input)
        return {} unless parsed

        parsed.delete_if { |_, value| value.nil? }.symbolize_keys
      end

      private

      def params_without_input
        pattern.captures_default.merge(attributes.params)
      end

      def upcase_method(method)
        method_s = method.to_s
        Grape::Http::Headers.find_supported_method(method_s) || method_s.upcase
      end
    end
  end
end
