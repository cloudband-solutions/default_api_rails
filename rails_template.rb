# rails_template.rb

require "fileutils"
require "open-uri"

after_bundle do
  app_name = File.basename(Dir.pwd)
  app_module_name = app_name.gsub(/(?:^|_)([a-z])/) { Regexp.last_match(1).upcase }

  # ------------------------------
  # CONFIG
  # ------------------------------
  template_repo = "https://github.com/cloudband-solutions/default_api_rails"
  template_zip_url = "#{template_repo}/archive/refs/heads/master.zip"
  template_name = "default_api_rails-master"

  say "📦 Downloading template from GitHub...", :green

  zip_path = "/tmp/#{app_name}_template.zip"
  extract_path = "/tmp/#{app_name}_template"

  File.open(zip_path, "wb") do |file|
    URI.open(template_zip_url) { |zip| file.write(zip.read) }
  end

  run "unzip -q -o #{zip_path} -d #{extract_path}"
  source_dir = File.join(extract_path, template_name)

  say "📂 Copying template files...", :green
  directory source_dir, ".", force: true, verbose: false, exclude_pattern: %w[.git log tmp node_modules]

  say "🔁 Replacing module DefaultApiRails → #{app_module_name}", :green

  files = Dir.glob("**/*.{rb,rake,erb,slim,haml,yml,yaml,js,json,md}", File::FNM_DOTMATCH)
             .reject { |f| File.directory?(f) }

  files.each do |file|
    gsub_file file, "DefaultApiRails", app_module_name
    gsub_file file, "default_api_rails", app_name
  end

  say "✅ Your app '#{app_name}' is ready!", :green
end
