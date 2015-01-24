module Interdasting
  module Router
    class << self
      def api_full
        result = {}
        versions.each { |v| result[v] = {} }
        result.each { |k, v| fill_controller_hash_for_version(k, v) }
        result
      end

      def api_controller_paths(controllers = api_controllers)
        cp = controllers.map do |c|
          c.instance_methods(false).map do |m|
            c.instance_method(m).source_location.first
          end
        end
        cp.flatten.uniq.compact
      end

      def api_controllers(names = api_controller_names)
        names.map do |cn|
          cn += '_controller'
          cn.classify.constantize
        end
      end

      def api_controller_names
        ar = routes.named_routes.select { |_k, v| v.defaults[:rp_prefix] }
        ar.values.map { |r| r.defaults[:controller] }.uniq
      end

      def routes_for_version(version)
        routes.to_a.select { |v| v && v.defaults[:version] == version }
      end

      def versions
        routes.to_a.map { |r| r && r.defaults[:version] }.uniq.compact
      end

      def routes
        app_routes.routes
      end

      def app_routes
        Rails.application.class.routes
      end

      private

      def fill_controller_hash_for_version(version, hash)
        routes = routes_for_version(version)
        routes.each do |r|
          cn = r.defaults[:controller]
          ch = hash[cn] ||= { actions: {} }
          ch[:path] ||= api_controller_paths(api_controllers([cn])).first
          ch[:actions][r.defaults[:action]] ||= []
          ch[:actions][r.defaults[:action]] << r.constraints[:request_method]
        end
      end
    end
  end
end