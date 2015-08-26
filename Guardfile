# A sample Guardfile
# More info at https://github.com/guard/guard#readme

ignore %r{^.git/}, %r{^_projects/}

guard :bundler do
  watch('Gemfile')
  # Uncomment next line if your Gemfile contains the `gemspec' command.
  # watch(/^.+\.gemspec/)
end

guard :minitest, cmd: 'bin/rake test' do
  # with Minitest::Unit
  watch(%r{^test\/(.*)\/?test_(.*)\.rb$})
  watch(%r{^lib\/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r{^test\/test_helper\.rb$})      { 'test' }

  # with Minitest::Spec
  # watch(%r{^spec/(.*)_spec\.rb$})
  # watch(%r{^lib/(.+)\.rb$})         { |m| "spec/#{m[1]}_spec.rb" }
  # watch(%r{^spec/spec_helper\.rb$}) { 'spec' }

  # Rails 4
  watch(%r{^app\/(.+)\.rb$})                               { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^app\/controllers\/application_controller\.rb$}) { 'test/controllers' }
  watch(%r{^app\/controllers\/(.+)_controller\.rb$})        { |m| "test/integration/#{m[1]}_test.rb" }
  watch(%r{^app\/views/(.+)_mailer/.+})                    { |m| "test/mailers/#{m[1]}_mailer_test.rb" }
  watch(%r{^lib\/(.+)\.rb$})                               { |m| "test/lib/#{m[1]}_test.rb" }
  watch(%r{^test\/.+_test\.rb$})
  watch(%r{^test\/test_helper\.rb$})                       { 'test' }
  watch(%r{^db\/seeds\.rb$})                               { 'test' }
end