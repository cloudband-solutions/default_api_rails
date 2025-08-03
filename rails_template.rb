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

  say "📂 Copying template files into #{app_name}...", :green

  excludes = [".git", "log", "tmp", "node_modules"]
  Dir.glob("#{source_dir}/**/*", File::FNM_DOTMATCH).each do |src_path|
    next if src_path == source_dir
    rel_path = Pathname.new(src_path).relative_path_from(Pathname.new(source_dir)).to_s
    next if excludes.any? { |pattern| rel_path.start_with?(pattern) }

    dest_path = File.join(Dir.pwd, rel_path)
    if File.directory?(src_path)
      FileUtils.mkdir_p(dest_path)
    else
      FileUtils.cp(src_path, dest_path)
    end
  end

  say "📦 Using template's Gemfile...", :green
  copy_file File.join(source_dir, "Gemfile"), "Gemfile", force: true
  copy_file File.join(source_dir, "Gemfile.lock"), "Gemfile.lock", force: true if File.exist?(File.join(source_dir, "Gemfile.lock"))

  say "📦 Re-installing bundle...", :green
  run "bundle install"

  say "🔁 Replacing 'DefaultApiRails' → '#{app_module_name}'", :green
  files = Dir.glob("**/*.{rb,yml,yaml,erb,haml,slim,js,json,md}", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }

  files.each do |file|
    gsub_file file, "DefaultApiRails", app_module_name
    gsub_file file, "default_api_rails", app_name
  end

  # Reset credentials to avoid master.key mismatch
  say "🔐 Resetting credentials to avoid master.key mismatch...", :green
  remove_file "config/credentials.yml.enc"
  remove_file "config/master.key"
  run "EDITOR=true rails credentials:edit"

  # ✅ Fix FrozenError: Replace autoload_paths << with Zeitwerk-friendly syntax
  say "🛠️ Patching config/application.rb to avoid FrozenError...", :green
  gsub_file "config/application.rb", /config\.autoload_paths\s*<<\s*["'](.+?)["']/, 'Rails.autoloaders.main.push_dir(Rails.root.join("\1"))'
  gsub_file "config/application.rb", /config\.autoload_paths\s*\+=\s*\[(.+?)\]/ do |match|
    paths = match.match(/\[(.+?)\]/)[1].split(",").map(&:strip)
    paths.map! { |p| "Rails.root.join(#{p}).to_s" }
    "config.autoload_paths += [#{paths.join(', ')}]"
  end

  say "✅ App '#{app_name}' is ready, autoload-safe, and customized!", :green
end
