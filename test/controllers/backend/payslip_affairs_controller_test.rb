require 'test_helper'
module Backend
  class PayslipAffairsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    # TODO: Re-activate #attach, #detach, :detach_gaps and #select tests
    test_restfully_all_actions except: %i[attach detach detach_gaps select]
  end
end
