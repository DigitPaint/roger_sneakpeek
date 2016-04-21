require "shellwords"
require "roger/test"
require "tempfile"
require "faraday"
require "uri"

require File.dirname(__FILE__) + "/git"

module RogerSneakpeek
  # Finalizer to zip and upload release
  class Finalizer < Roger::Release::Finalizers::Base
    attr_reader :release, :current_options

    def call(release, call_options = {})
      options = {
        zip: "zip",
        project: nil,
        gitlab_project: nil,
        ci_only: true,
        sneakpeek_api_url: "http://api.peek.digitpaint.nl"
      }.update(@options)

      options.update(call_options) if call_options

      unless options[:project]
        fail ArgumentError, "You must specify a project to the RogerSneakpeek"
      end

      unless options[:gitlab_project]
        fail ArgumentError, "You must specify a gitlab_project to RogerSneakpeek"
      end

      # If we run in ci_only mode and are not in CI we stop.
      return if options[:ci_only] && !ENV["CI"]

      @release = release
      @current_options = options

      check_zip_command

      release.log(self, "Starting upload to Sneakpeek")
      upload_release zip_release
    end

    protected

    def zip_command(*args)
      ([Shellwords.escape(current_options[:zip])] + args).join(" ")
    end

    def check_zip_command
      `#{zip_command} -v`
    rescue Errno::ENOENT
      raise "Could not find zip in #{zip_command.inspect}"
    end

    def git(*args)
      cmd = Shellwords.join([current_options[:git]] + args)
      `#{cmd}`
    end

    def zip_release
      zip_path = Dir::Tmpname.create ["release", ".zip"] {}
      ::Dir.chdir(release.build_path) do
        command = zip_command("-r", "-9", Shellwords.escape(zip_path), "./*")
        output = `#{command}`
        fail "Could not generate zipfile\n#{output}" if $CHILD_STATUS.to_i != 0
      end

      zip_path
    end

    def upload_release(zip_path)
      project = current_options[:project]
      git = Git.new(path: release.project.path)

      case
      when git.tag
        url = "/projects/#{project}/tags/#{URI.escape(git.tag)}"
      when git.branch
        url = "/projects/#{project}/branches/#{URI.escape(git.branch)}"
      else
        fail "Current project is neither on a tag nor a branch"
      end

      params = {
        sha: git.sha,
        gitlab_project: current_options[:gitlab_project]
      }

      perform_upload(url, zip_path, params)
    ensure
      File.unlink zip_path
    end

    def perform_upload(url, zip_path, params)
      conn = Faraday.new(current_options[:sneakpeek_api_url]) do |f|
        f.request :multipart
        f.request :url_encoded
        f.adapter :net_http
      end

      data = params.dup
      data[:file] = Faraday::UploadIO.new(zip_path, "application/zip")

      result = conn.post(url, data)

      fail "Upload to Sneakpeek failed" if result.status != 200
    end
  end
end

Roger::Release::Finalizers.register(:sneakpeek, RogerSneakpeek::Finalizer)
