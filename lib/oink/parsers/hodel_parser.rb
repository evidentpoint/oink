module Oink
  module Parsers
    class HodelParser
      HODEL_LOG_FORMAT_REGEX = /^(\w+ \d{2} \d{2}:\d{2}:\d{2})/.freeze
      PID_REGEX = /rails\[(\d+)\]/.freeze
      def self.parse(line)
        return nil unless line =~ HODEL_LOG_FORMAT_REGEX
        date = $1
        return nil unless line =~ PID_REGEX
        pid = $1
        return { date: date, pid: pid }
      end
    end
  end
end
