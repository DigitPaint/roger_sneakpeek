require "shellwords"
require "roger/test"
require "tempfile"
require "faraday"
require "uri"
require "json"

require File.dirname(__FILE__) + "/git"
require File.dirname(__FILE__) + "/ci"

module RogerSneakpeek
  # Finalizer to zip and upload release
  class Finalizer < Roger::Release::Finalizers::Base
    self.name = :sneakpeek

    def default_options
      {
        zip: "zip",
        project: nil,
        gitlab_project: nil,
        ci_only: true,
        sneakpeek_api_url: "http://api.peek.digitpaint.nl"
      }
    end

    def perform
      unless @options[:project]
        fail ArgumentError, "You must specify a project to RogerSneakpeek"
      end

      unless @options[:gitlab_project]
        fail ArgumentError, "You must specify a gitlab_project to RogerSneakpeek"
      end

      # If we run in ci_only mode and are not in CI we stop.
      return if @options[:ci_only] && !CI.ci?

      check_zip_command

      @release.log(self, "Starting upload to Sneakpeek")
      upload_release zip_release
    end

    protected

    def zip_command(*args)
      ([Shellwords.escape(@options[:zip])] + args).join(" ")
    end

    def check_zip_command
      `#{zip_command} -v`
    rescue Errno::ENOENT
      raise "Could not find zip in #{zip_command.inspect}"
    end

    def git(*args)
      cmd = Shellwords.join([@options[:git]] + args)
      `#{cmd}`
    end

    def zip_release
      zip_path = Dir::Tmpname.create ["release", ".zip"] {}
      ::Dir.chdir(@release.build_path) do
        command = zip_command("-r", "-9", Shellwords.escape(zip_path), "./*")
        output = `#{command}`
        fail "Could not generate zipfile\n#{output}" if $CHILD_STATUS.to_i != 0
      end

      zip_path
    end

    def upload_release(zip_path)
      if CI.ci?
        git = CI.new()
      else
        git = Git.new(path: @release.project.path)
      end

      data = perform_upload(
        sneakpeek_url(git),
        zip_path,
        sha: git.sha,
        gitlab_project: @options[:gitlab_project]
      )

      @release.log(self, "Sneakpeek url: #{data['url']}") if data
    ensure
      File.unlink zip_path
    end

    def sneakpeek_url(git)
      project = @options[:project]
      case
      when git.tag
        "/projects/#{project}/tags/#{URI.escape(git.tag)}"
      when git.branch
        "/projects/#{project}/branches/#{URI.escape(git.branch)}"
      else
        fail "Current project is neither on a tag nor a branch"
      end
    end

    def perform_upload(url, zip_path, params)
      conn = Faraday.new(@options[:sneakpeek_api_url]) do |f|
        f.request :multipart
        f.request :url_encoded
        f.adapter :net_http
      end

      data = params.dup
      data[:file] = Faraday::UploadIO.new(zip_path, "application/zip")

      result = conn.post(url, data)

      case result.status
      when 201
        JSON.parse(result.body)
      when 422
        fail "Upload to Sneakpeek failed with error: #{response.body[:error]}"
      else
        fail "Upload to Sneakpeek failed with unknown error (status: #{result.status})"
      end
    end
  end
end

Roger::Release::Finalizers.register(:sneakpeek, RogerSneakpeek::Finalizer)
