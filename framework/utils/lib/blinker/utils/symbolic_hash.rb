module Blinker
  module Utils
    class SymbolicHash
      def self.wrap hash, mapping = {}
        symbolic = Hash.new { |h,k|
          k = k.to_s if k.is_a? Symbol
          (h.has_key? k) ? h[k] : nil
        }

        mapping[hash] = symbolic

        hash.each_pair { |key, value|
          symbolic[key] = handle_object value, mapping
        }

        symbolic
      end

      protected
      def self.handle_object object, mapping
        if object.is_a? Hash
          handle_hash object, mapping
        elsif object.is_a? Array
          handle_array object, mapping
        else
          object
        end
      end

      def self.handle_array array, mapping
        mapping[array] ||= array.map { |e|
          handle_object e, mapping
        }
      end

      def self.handle_hash hash, mapping
        mapping[hash] ||= SymbolicHash.wrap hash, mapping
      end
    end
  end
end
