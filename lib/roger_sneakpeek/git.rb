module RogerSneakpeek
  # Get relevant git info
  class Git < Roger::Release::Scm::Git
    def tag
      get_scm_data if @_sha.nil?
      @_tag
    end

    def sha
      get_scm_data if @_sha.nil?
      @_sha
    end

    # Will return current branch
    def branch
      get_scm_data if @_sha.nil?
      @_branch
    end

    protected

    def get_scm_data(ref = @config[:ref])
      super(ref)

      @_tag = scm_tag(ref) || nil
      @_branch = scm_branch(ref) || nil
      @_sha = scm_sha(ref) || nil
    end

    def scm_tag(ref)
      return nil unless File.exist?(git_dir)

      tag = `git --git-dir=#{safe_git_dir} describe --tags #{ref} 2>&1`

      tag.strip if $CHILD_STATUS.to_i == 0
    end

    def scm_branch(ref)
      return nil unless File.exist?(git_dir)

      branch = `git --git-dir=#{safe_git_dir} rev-parse --abbrev-ref #{ref} 2>&1`

      branch.strip if $CHILD_STATUS.to_i == 0
    end

    def scm_sha(ref)
      return nil unless File.exist?(git_dir)

      sha = `git --git-dir=#{safe_git_dir} show #{ref} --format=format:"%H" -s 2>&1`

      sha.strip if $CHILD_STATUS.to_i == 0
    end
  end
end
