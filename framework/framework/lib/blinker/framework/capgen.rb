require 'selenium-webdriver'
require 'headless'

module Blinker
  module Framework
    module Capgen
      def with_webdriver &blk
        Headless.ly(reuse: false, autopick: true) do
          driver = Selenium::WebDriver.for :chrome
          blk.call(driver)
          driver.quit
        end
      end

      extend self
    end
  end
end
