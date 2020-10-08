require 'grape'
require 'pagy'
require 'pagy/extras/arel'
require 'pagy/extras/array'
require 'pagy/extras/headers'
require 'pagy/extras/items'
require 'pagy/extras/overflow'

module Grape
  module Pagy
    Wrapper = Struct.new :request, :params do
      include ::Pagy::Backend

      def paginate(collection, via: nil, **opts, &block)
        pagy_with_items(opts)
        via ||= if collection.respond_to?(:arel_table)
                  :arel
                elsif collection.is_a?(Array)
                  :array
                end

        method = [:pagy, via].compact.join('_')
        page, scope = send(method, collection, **opts)

        pagy_headers(page).each(&block)
        scope
      end
    end

    module Helpers
      extend Grape::API::Helpers

      params :pagy do |items: nil, page: nil, **opts|
        items ||= ::Pagy::VARS[:items]
        page ||= ::Pagy::VARS[:page]
        page_param = opts[:page_param] || ::Pagy::VARS[:page_param]
        items_param = opts[:items_param] || ::Pagy::VARS[:items_param]

        @api.route_setting(:pagy_options, opts)
        optional page_param, type: Integer, default: page, desc: 'Page offset to fetch.'
        optional items_param, type: Integer, default: items, desc: 'Number of items to return per page.'
      end

      # @param [Array|ActiveRecord::Relation] collection the collection or relation.
      def pagy(collection, **opts)
        defaults = route_setting(:pagy_options) || {}
        Wrapper.new(request, params).paginate(collection, **defaults, **opts) do |key, value|
          header key, value
        end
      end
    end
  end
end
