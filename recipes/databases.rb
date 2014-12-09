include_recipe 'database::mysql'
include_recipe 'database::postgresql'

node_root = node['rails_app']

node_root['apps'].each do |name, app_config|
  data_bag = data_bag_item('rails_app', name)

  app_config['environments'].each do |environment|
    db_config = app_config['environment_config'][environment]['database']
    adapter = db_config['adapter']

    rdbms = (adapter == 'mysql2' ? 'mysql' : adapter)
    db_connection = node_root[rdbms]

    case rdbms
    when 'mysql'
      db_provider   = Chef::Provider::Database::Mysql
      user_provider = Chef::Provider::Database::MysqlUser
    when 'postgresql'
      db_provider   = Chef::Provider::Database::Postgresql
      user_provider = Chef::Provider::Database::PostgresqlUser
    else
      raise "Unknown adapter: #{db_config['adapter']}"
    end

    database db_config['database'] do
      connection db_connection
      provider   db_provider
      encoding   db_config['encoding'] || 'utf8'

      if db_config['collation']
        collation db_config['collation']
      end

      action :create
    end

    %w[% localhost 127.0.0.1].each do |db_host|
      database_user db_config['user'] do
        connection  db_connection
        provider    user_provider
        host        db_host
        password    data_bag[environment]['database_password']
        action      :create
      end

      database_user db_config['user'] do
        connection    db_connection
        provider      user_provider
        host          db_host
        database_name db_config['database']
        action        :grant
      end
    end
  end
end
