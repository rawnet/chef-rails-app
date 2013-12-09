rails_apps = node['rails_app']['apps']
jetty_user = node['jetty']['user']
rails_user = node['rails_app']['rails_user']

rails_apps.each_pair do |app_name, app_config|
  app_root = File.join('/', 'home', rails_user, 'apps', app_name)

  app_config['environments'].each do |environment|
    shared_dir = File.join(app_root, environment, 'shared')

    directory File.join(shared_dir, 'solr') do
      owner rails_user
      group rails_user
      recursive true
    end

    directory File.join(shared_dir, 'solr', 'data') do
      owner jetty_user
      group jetty_user
      recursive true
    end

    remote_directory File.join(shared_dir, 'solr', 'config') do
      owner jetty_user
      group jetty_user
      source 'solr_config'
    end
  end
end

template File.join(node['solr']['home'], 'solr.xml') do
  owner jetty_user
  group jetty_user
  source 'solr.xml.erb'
  variables(rails_apps: rails_apps, rails_user: rails_user)
  notifies :restart, "service[jetty]", :delayed
end
