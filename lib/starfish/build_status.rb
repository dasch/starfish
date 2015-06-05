module Starfish
  class BuildStatus
    def initialize(status_checks)
      @status_checks = status_checks
    end

    def status
      if @status_checks.all?(&:ok?)
        :ok
      elsif @status_checks.any?(&:pending?)
        :pending
      elsif @status_checks.any?(&:failed?)
        :failed
      else
        raise "what now?"
      end
    end

    def ok?
      status == :ok
    end

    def failed?
      status == :failed
    end

    def pending?
      status == :pending
    end
  end
end
