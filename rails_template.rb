# rails_template.rb

require "open-uri"
require "fileutils"

after_bundle do
  app_name = File.basename(Dir.pwd)
  app_module_name = app_name.split('_').map(&:capitalize).join

  template_repo = "https://github.com/cloudband-solutions/default_api_rails"
  template_zip_url = "#{template_repo}/archive/refs/heads/master.zip"
  template_name = "default_api_rails-master"

  say "📦 Downloading template from GitHub...", :green

  zip_path = "/tmp/#{app_name}_template.zip"
  extract_path = "/tmp/#{app_name}_template"
  FileUtils.mkdir_p extract_path

  File.open(zip_path, "wb") do |file|
    URI.open(template_zip_url) { |zip| file.write(zip.read) }
  end

  run "unzip -q -o #{zip_path} -d #{extract_path}"
  source_dir = File.join(extract_path, template_name)

  say "📂 Copying files from template...", :green
  directory source_dir, ".", force: true, exclude_pattern: %w[.git log tmp node_modules]

  say "🔁 Replacing module and name...", :green
  files = Dir.glob("**/*.{rb,yml,yaml,erb,haml,slim,js,json,md}", File::FNM_DOTMATCH)
             .reject { |f| File.directory?(f) }

  files.each do |file|
    gsub_file file, "DefaultApiRails", app_module_name
    gsub_file file, "default_api_rails", app_name
  end

  say "✅ Done! Your app '#{app_name}' is ready.", :green
end
