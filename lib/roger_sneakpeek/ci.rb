module RogerSneakpeek
  # Get relevant git info
  class CI
    # Are we running in CI?
    def self.ci?
      ENV["CI"]
    end

    def tag
      ENV["CI_BUILD_TAG"]
    end

    def sha
      ENV["CI_BUILD_REF"]
    end

    # Will return current branch or tag
    # in CI mode.
    def branch
      ENV["CI_BUILD_REF_NAME"]
    end
  end
end
