module Oink
  module Parsers
    class StdlibParser
      REGEX = /^[A-Z], \[(\d+-\d+-\d+T\d+:\d+:\d+\.\d+) #(\d+)\]/.freeze
      def self.parse(line)
        return line =~ REGEX ? { date: $1, pid: $2 } : nil
      end
    end
  end
end
