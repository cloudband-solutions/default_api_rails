# rails_template.rb

# Save and reuse the app name
app_name = app_name.camelize

# Customize post-bundle steps
after_bundle do
  # Fix module name in application.rb
  gsub_file("config/application.rb", /module\s+\w+/, "module #{app_name}")

  # (Optional) Rename any other relevant module/class names
  # gsub_file("config/environment.rb", /DefaultApi/, app_name)

  # Setup other tasks: e.g., RSpec, CORS, folder structures, etc.
end
