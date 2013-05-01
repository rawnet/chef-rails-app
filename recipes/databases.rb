
include_recipe "database::mysql"

rails_apps = data_bag('rails_apps')

mysql_connection_info = {
  :host => "localhost",
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

rails_apps.each do |app_name|

  app = data_bag_item('rails_apps', app_name)

  app['environments'].each do |environment, config|

    db = config['database']

    mysql_database db['database'] do
      connection mysql_connection_info
      action :create
    end

    mysql_database_user db['user'] do
      connection mysql_connection_info
      host '%'
      password db['password']
      action :create
    end

    mysql_database_user db['user'] do
      connection mysql_connection_info
      database_name db['database']
      action :grant
    end

  end

end