# I am not proud of this...

class << self
  alias :old_extend :extend
  def extend mod
    old_extend mod unless (Rake::DSL rescue nil) == mod
  end
end

require 'rake'

class << self
  alias :extend :old_extend
  remove_method :old_extend
end

# Do not let Rake catch & pretty print exceptions
module Rake
  class Application
    def standard_exception_handling
      yield
    end
  end
end

class RakeDSL
  class Plug
    self.extend Rake::DSL
  end

  def self.method_missing symbol, *args, &blk
    Plug.send(symbol, *args, &blk)
  end
end
