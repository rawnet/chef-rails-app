include_recipe "mysql::server"
include_recipe "database::mysql"

rails_apps = node["rails_app"]["apps"]

mysql_connection_info = {
  :host => "localhost",
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

rails_apps.each_pair do |app_name, app_config|
  
  environments = app_config["environments"]

  app = data_bag_item('rails_apps', app_name)

  environments.each do |environment|
    
    node_config = {}
    environment, node_config = environment.first if environment.is_a?(Hash)
    
    config = app["environments"][environment]
    
    if node_config.has_key?("database")
      db_config = config['database'].merge(node_config['database'])
    else
      db_config = config['database']
    end
    

    mysql_database db_config['database'] do
      connection mysql_connection_info
      action :create
    end

    %w(% localhost 127.0.0.1).each do |mysql_host|
      mysql_database_user db_config['user'] do
        connection mysql_connection_info
        host mysql_host
        password db_config['password']
        action :create
      end
    end

    mysql_database_user db_config['user'] do
      connection mysql_connection_info
      database_name db_config['database']
      action :grant
    end

  end

end
