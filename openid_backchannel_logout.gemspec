# frozen_string_literal: true

require_relative 'lib/openid_backchannel_logout/version'

Gem::Specification.new do |spec|
  spec.name = 'openid_backchannel_logout'
  spec.version = OpenidBackchannelLogout::VERSION
  spec.authors = ['Nguyen Ngoc Hai']
  spec.email = ['ngochai220998@gmail.com']

  spec.summary = 'A Ruby implementation of OpenID Connect Backchannel Logout'
  spec.description = 'A Ruby implementation of OpenID Connect Backchannel Logout, as defined in the OpenID Connect Back-Channel Logout 1.0 specification.'
  spec.homepage = 'https://github.com/NgocHai220998/openid_backchannel_logout.git'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['allowed_push_host'] = 'https://github.com/NgocHai220998/openid_backchannel_logout.git' # TODO: Update

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/NgocHai220998/openid_backchannel_logout.git'
  spec.metadata['changelog_uri'] = 'https://github.com/NgocHai220998/openid_backchannel_logout.git' # TODO: Update

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'jwt'
  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
