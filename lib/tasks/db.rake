namespace :db do
  desc "Refresh collation version and optionally reindex database"
  task refresh_collation: :environment do
    db_name = ActiveRecord::Base.connection.current_database
    puts "Refreshing collation version for #{db_name}..."

    begin
      ActiveRecord::Base.connection.execute("ALTER DATABASE #{db_name} REFRESH COLLATION VERSION;")
      puts "✅ Collation version refreshed."

      # Optional: Reindex entire database (lock-heavy, so do this only on dev/test)
      puts "Reindexing database (this may lock tables)..."
      ActiveRecord::Base.connection.execute("REINDEX DATABASE #{db_name};")
      puts "✅ Reindexing complete."

    rescue => e
      puts "❌ Failed: #{e.message}"
    end
  end

  desc "Refresh collation and reindex collation-sensitive indexes concurrently (safe for large DBs)"
  task refresh_collation_concurrent: :environment do
    db_name = ActiveRecord::Base.connection.current_database
    puts "Refreshing collation version for database: #{db_name}"

    begin
      # Step 1: Refresh collation version metadata
      ActiveRecord::Base.connection.execute("ALTER DATABASE #{db_name} REFRESH COLLATION VERSION;")
      puts "✅ Collation version refreshed."

      # Step 2: Query user-defined indexes on text/varchar columns (excluding system catalogs)
      indexes_sql = <<~SQL
        SELECT DISTINCT i.relname AS index_name, n.nspname AS schema_name
        FROM pg_index ix
        JOIN pg_class i ON i.oid = ix.indexrelid
        JOIN pg_class t ON t.oid = ix.indrelid
        JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = ANY(ix.indkey)
        JOIN pg_namespace n ON n.oid = i.relnamespace
        WHERE a.atttypid IN ('text'::regtype, 'varchar'::regtype)
          AND ix.indisvalid
          AND ix.indisready
          AND n.nspname NOT IN ('pg_catalog', 'information_schema')
      SQL

      results = ActiveRecord::Base.connection.execute(indexes_sql)
      index_names = results.map { |row| "#{row['schema_name']}.#{row['index_name']}" }

      if index_names.empty?
        puts "ℹ️ No collation-sensitive indexes found."
      else
        puts "Reindexing #{index_names.size} index(es) concurrently:"
        index_names.each do |index_full_name|
          puts "  → Reindexing #{index_full_name}"
          ActiveRecord::Base.connection.execute("REINDEX INDEX CONCURRENTLY #{index_full_name};")
        end
        puts "✅ All affected indexes reindexed."
      end

    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
end
