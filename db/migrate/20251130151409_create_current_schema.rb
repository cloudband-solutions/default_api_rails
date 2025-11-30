class CreateCurrentSchema < ActiveRecord::Migration[8.1]
  def change
    enable_extension "pg_catalog.plpgsql" unless extension_enabled?("pg_catalog.plpgsql")
    enable_extension "pgcrypto" unless extension_enabled?("pgcrypto")

    create_table :users, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.datetime :created_at, null: false
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :status, null: false
      t.datetime :updated_at, null: false
    end

    create_table :solid_cache_entries do |t|
      t.binary :key, limit: 1024, null: false
      t.binary :value, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :key_hash, limit: 8, null: false
      t.integer :byte_size, limit: 4, null: false
    end

    add_index :solid_cache_entries, :byte_size, name: "index_solid_cache_entries_on_byte_size"
    add_index :solid_cache_entries, %i[key_hash byte_size], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    add_index :solid_cache_entries, :key_hash, name: "index_solid_cache_entries_on_key_hash", unique: true

    create_table :solid_cable_messages do |t|
      t.binary :channel, limit: 1024, null: false
      t.binary :payload, limit: 536_870_912, null: false
      t.datetime :created_at, null: false
      t.integer :channel_hash, limit: 8, null: false
    end

    add_index :solid_cable_messages, :channel, name: "index_solid_cable_messages_on_channel"
    add_index :solid_cable_messages, :channel_hash, name: "index_solid_cable_messages_on_channel_hash"
    add_index :solid_cable_messages, :created_at, name: "index_solid_cable_messages_on_created_at"

    create_table :solid_queue_blocked_executions do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, null: false, default: 0
      t.string :concurrency_key, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_blocked_executions, %i[concurrency_key priority job_id],
              name: "index_solid_queue_blocked_executions_for_release"
    add_index :solid_queue_blocked_executions, %i[expires_at concurrency_key],
              name: "index_solid_queue_blocked_executions_for_maintenance"
    add_index :solid_queue_blocked_executions, :job_id,
              name: "index_solid_queue_blocked_executions_on_job_id", unique: true

    create_table :solid_queue_claimed_executions do |t|
      t.bigint :job_id, null: false
      t.bigint :process_id
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_claimed_executions, :job_id,
              name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    add_index :solid_queue_claimed_executions, %i[process_id job_id],
              name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"

    create_table :solid_queue_failed_executions do |t|
      t.bigint :job_id, null: false
      t.text :error
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_failed_executions, :job_id,
              name: "index_solid_queue_failed_executions_on_job_id", unique: true

    create_table :solid_queue_jobs do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments
      t.integer :priority, null: false, default: 0
      t.string :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string :concurrency_key
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :solid_queue_jobs, :active_job_id,
              name: "index_solid_queue_jobs_on_active_job_id"
    add_index :solid_queue_jobs, :class_name,
              name: "index_solid_queue_jobs_on_class_name"
    add_index :solid_queue_jobs, :finished_at,
              name: "index_solid_queue_jobs_on_finished_at"
    add_index :solid_queue_jobs, %i[queue_name finished_at],
              name: "index_solid_queue_jobs_for_filtering"
    add_index :solid_queue_jobs, %i[scheduled_at finished_at],
              name: "index_solid_queue_jobs_for_alerting"

    create_table :solid_queue_pauses do |t|
      t.string :queue_name, null: false
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_pauses, :queue_name, name: "index_solid_queue_pauses_on_queue_name", unique: true

    create_table :solid_queue_processes do |t|
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.bigint :supervisor_id
      t.integer :pid, null: false
      t.string :hostname
      t.text :metadata
      t.datetime :created_at, null: false
      t.string :name, null: false
    end

    add_index :solid_queue_processes, :last_heartbeat_at,
              name: "index_solid_queue_processes_on_last_heartbeat_at"
    add_index :solid_queue_processes, %i[name supervisor_id],
              name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    add_index :solid_queue_processes, :supervisor_id,
              name: "index_solid_queue_processes_on_supervisor_id"

    create_table :solid_queue_ready_executions do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, null: false, default: 0
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_ready_executions, :job_id,
              name: "index_solid_queue_ready_executions_on_job_id", unique: true
    add_index :solid_queue_ready_executions, %i[priority job_id],
              name: "index_solid_queue_poll_all"
    add_index :solid_queue_ready_executions, %i[queue_name priority job_id],
              name: "index_solid_queue_poll_by_queue"

    create_table :solid_queue_recurring_executions do |t|
      t.bigint :job_id, null: false
      t.string :task_key, null: false
      t.datetime :run_at, null: false
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_recurring_executions, :job_id,
              name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    add_index :solid_queue_recurring_executions, %i[task_key run_at],
              name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true

    create_table :solid_queue_recurring_tasks do |t|
      t.string :key, null: false
      t.string :schedule, null: false
      t.string :command, limit: 2048
      t.string :class_name
      t.text :arguments
      t.string :queue_name
      t.integer :priority, default: 0
      t.boolean :static, null: false, default: true
      t.text :description
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :solid_queue_recurring_tasks, :key,
              name: "index_solid_queue_recurring_tasks_on_key", unique: true
    add_index :solid_queue_recurring_tasks, :static,
              name: "index_solid_queue_recurring_tasks_on_static"

    create_table :solid_queue_scheduled_executions do |t|
      t.bigint :job_id, null: false
      t.string :queue_name, null: false
      t.integer :priority, null: false, default: 0
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false
    end

    add_index :solid_queue_scheduled_executions, :job_id,
              name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    add_index :solid_queue_scheduled_executions, %i[scheduled_at priority job_id],
              name: "index_solid_queue_dispatch_all"

    create_table :solid_queue_semaphores do |t|
      t.string :key, null: false
      t.integer :value, null: false, default: 1
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    add_index :solid_queue_semaphores, :expires_at,
              name: "index_solid_queue_semaphores_on_expires_at"
    add_index :solid_queue_semaphores, %i[key value],
              name: "index_solid_queue_semaphores_on_key_and_value"
    add_index :solid_queue_semaphores, :key,
              name: "index_solid_queue_semaphores_on_key", unique: true

    add_foreign_key :solid_queue_blocked_executions, :solid_queue_jobs,
                    column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs,
                    column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs,
                    column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions, :solid_queue_jobs,
                    column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs,
                    column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs,
                    column: :job_id, on_delete: :cascade
  end
end
