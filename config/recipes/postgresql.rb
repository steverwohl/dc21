namespace :postgresql do

  task :setup do
    run %Q{#{try_sudo} service postgresql initdb}

    #refresh pg_hba.conf

    run %Q{#{try_sudo} truncate -s0 /var/lib/pgsql/data/pg_hba.conf}
    run %Q{echo "local all all  trust" | #{try_sudo} tee -a /var/lib/pgsql/data/pg_hba.conf}
    run %Q{echo "host all all 127.0.0.1/32 password" | #{try_sudo} tee -a /var/lib/pgsql/data/pg_hba.conf}
    run %Q{echo "host all all ::1/128 password" | #{try_sudo} tee -a /var/lib/pgsql/data/pg_hba.conf}

    run %Q{#{try_sudo} service postgresql start}

    buffer = YAML::load_file('config/database.yml')

    postgresql_user = buffer[rails_env]['username']
    postgresql_password = buffer[rails_env]['password']
    postgresql_database = buffer[rails_env]['database']

    sudo %Q{psql -c "create user #{postgresql_user} with SUPERUSER password '#{postgresql_password}';"}, as: "postgres"
    sudo %Q{psql -c "create database #{postgresql_database};"}, as: "postgres"

  end

end