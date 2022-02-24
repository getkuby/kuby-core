# typed: true
module Kuby
  module Utils
    class Table
      attr_reader :headers, :rows

      def initialize(headers, rows)
        @headers = headers
        @rows = rows
      end

      def to_s
        [headers, *rows].map { |vals| make_row(vals) }.join("\n")
      end

      private

      def make_row(values)
        columns = values.each_with_index.map do |value, idx|
          col_width = col_width_at(idx) + 2
          value.ljust(col_width, ' ')
        end

        columns.join
      end

      def col_width_at(idx)
        col_widths[idx] ||= [headers[idx].size, *rows.map { |r| r[idx].size }].max
      end

      def col_widths
        @col_widths ||= {}
      end
    end
  end
end