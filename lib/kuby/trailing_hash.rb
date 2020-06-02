module Kuby
  class TrailingHash < Hash
    def each
      return to_enum(__method__) unless block_given?

      seen_keys = []
      keys_before = keys

      until keys_before.empty?
        keys_before.each do |k|
          yield k, self[k]
          seen_keys << k
        end

        keys_before = keys - seen_keys
      end
    end
  end
end
