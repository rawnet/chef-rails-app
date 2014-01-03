include_recipe 'database::mysql'

mysql_connection_info = {
  :host     => 'localhost',
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

node_root = node['rails_app']

node_root['apps'].each do |name, app_config|
  data_bag = data_bag_item('rails_app', name)

  app_config['environments'].each do |environment|
    db_config = app_config['environment_config'][environment]['database']

    mysql_database db_config['database'] do
      connection mysql_connection_info
      action :create
    end

    %w[% localhost 127.0.0.1].each do |mysql_host|
      mysql_database_user db_config['user'] do
        connection mysql_connection_info
        host mysql_host
        password data_bag[environment]['database_password']
        action :create
      end

      mysql_database_user db_config['user'] do
        connection mysql_connection_info
        host mysql_host
        database_name db_config['database']
        action :grant
      end
    end
  end
end
