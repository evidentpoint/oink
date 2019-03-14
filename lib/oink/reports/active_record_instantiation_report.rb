require "date"
require "oink/reports/base"
require "oink/reports/active_record_instantiation_oinked_request"
require "oink/reports/priority_queue"

module Oink
  module Reports
    class ActiveRecordInstantiationReport < Base
      def print(output)
        oink_entry_count = 0
        output.puts "---- OINK FOR ACTIVERECORD ----"
        output.puts "THRESHOLD: #{@threshold} Active Record objects per request\n"

        output.puts "\n-- REQUESTS --\n" if @format == :verbose

        @inputs.each do |input|
          input.each_line do |line|
            line = line.strip

            # Skip this line since we're only interested in the Hodel 3000 compliant lines
            parsed = @parser.parse(line)
            next unless parsed

            date = parsed[:date]
            pid = parsed[:pid]

            # Check date threshold
            if @after_time || @before_time
              begin
                parsed_date = Time.parse(date)
                next if @after_time && parsed_date <= @after_time
                next if @before_time && parsed_date >= @before_time
              rescue => e
                STDERR.puts "Error parsing time: #{date}"
                next
              end
            end

            @pids[pid] ||= { :buffer => [], :ar_count => -1, :action => "", :request_finished => true }
            @pids[pid][:buffer] << line

            if line =~ /Oink Action: (([\w\/]+)#(\w+))/

              @pids[pid][:action] = $1
              unless @pids[pid][:request_finished]
                @pids[pid][:buffer] = [line]
              end
              @pids[pid][:request_finished] = false

            elsif line =~ /Instantiation Breakdown: Total: (\d+)/

              @pids[pid][:ar_count] = $1.to_i

            elsif line =~ /Oink Log Entry Complete/

              oink_entry_count += 1
              if @pids[pid][:ar_count] > @threshold
                @bad_actions[@pids[pid][:action]] ||= 0
                @bad_actions[@pids[pid][:action]] = @bad_actions[@pids[pid][:action]] + 1
                @bad_requests.push(ActiveRecordInstantiationOinkedRequest.new(@pids[pid][:action], date, @pids[pid][:buffer], @pids[pid][:ar_count]))
                if @format == :verbose
                  @pids[pid][:buffer].each { |b| output.puts b }
                  output.puts "---------------------------------------------------------------------"
                end
              end

              @pids[pid][:request_finished] = true
              @pids[pid][:buffer] = []
              @pids[pid][:ar_count] = -1

            end # end elsif
          end # end each_line
        end # end each input

        output.puts "---- Oink Entries Parsed: #{oink_entry_count} ----\n" if @format == :verbose
        print_summary(output)

      end
    end
  end
end
