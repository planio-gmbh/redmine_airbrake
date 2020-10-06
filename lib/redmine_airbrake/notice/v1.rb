# frozen_string_literal: true

module RedmineAirbrake
  module Notice
    class V1 < Base

      def fetch(key)
        @notice[":#{key}"] || @notice[key]
      end

      def initialize(data)
        require "safe_yaml/load"

        data = SafeYAML.load data
        @notice = data['notice']
        cfg = fetch 'api_key'
        @config = JSON.parse(cfg) rescue {}
        if @config.blank?
          @config = Hash[SafeYAML.load(cfg).map{|k,v| [k.to_s.sub( /\A:/,''), v]}]
        end

        # keys in notice:
        #:error_class   => exception.class.name,
        #:error_message => "#{exception.class.name}: #{exception.message}",
        #:backtrace     => exception.backtrace,
        @errors = [
          Error.new({
            'class' => fetch('error_class'),
            'message' => fetch('error_message'),
            'backtrace' => parse_backtrace(fetch('backtrace'))
          }, self)
        ]


        #:environment   => ENV.to_hash
        @env = fetch('environment')

        #:request => {
        #  :params      => request.parameters.to_hash,
        #  :rails_root  => File.expand_path(RAILS_ROOT),
        #  :url         => "#{request.protocol}#{request.host}#{request.request_uri}"
        #}
        @request = fetch('request')

        #:session => {
        #  :key         => session.instance_variable_get("@session_id"),
        #  :data        => session.instance_variable_get("@data")
        #}
        @session = fetch('session')[':data']


      end

      def parse_backtrace(lines)
        return [] if lines.blank?

        lines.map do |line|
          if line =~ /(.+):(\d+)(:in `(.+)')?/
            { 'number' => $2.to_i, 'method' => $4, 'file' => $1 }
          end
        end.compact
      end


    end
  end
end
