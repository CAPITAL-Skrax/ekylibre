require 'test_helper'
module Public
  class BaseControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions
  end
end
