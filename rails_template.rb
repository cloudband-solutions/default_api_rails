# rails_template.rb

require "fileutils"
require "open-uri"

after_bundle do
  app_name = File.basename(Dir.pwd)
  app_module_name = app_name.split('_').map(&:capitalize).join

  template_repo = "https://github.com/cloudband-solutions/default_api_rails"
  zip_url = "#{template_repo}/archive/refs/heads/master.zip"
  zip_path = "/tmp/#{app_name}_template.zip"
  extract_path = "/tmp/#{app_name}_template"
  template_dir_name = "default_api_rails-master"

  say "📦 Downloading template from #{zip_url}", :green

  FileUtils.mkdir_p extract_path

  File.open(zip_path, "wb") do |file|
    URI.open(zip_url) { |zip| file.write(zip.read) }
  end

  run "unzip -q -o #{zip_path} -d #{extract_path}"
  source_dir = File.join(extract_path, template_dir_name)

  say "📂 Copying files into #{app_name}...", :green
  directory source_dir, ".", force: true, exclude_pattern: %w[.git log tmp node_modules]

  say "🔁 Replacing 'DefaultApiRails' → #{app_module_name}", :green

  files = Dir.glob("**/*.{rb,yml,yaml,erb,haml,slim,js,json,md}", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  files.each do |file|
    gsub_file file, "DefaultApiRails", app_module_name
    gsub_file file, "default_api_rails", app_name
  end

  say "✅ App '#{app_name}' is ready and customized!", :green
end
