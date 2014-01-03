node_root = node['rails_app']
app_user = node_root['app_user']
jetty_user = node['jetty']['user']

node_root['apps'].each do |name, app_config|
  app_root = File.join('/', 'home', app_user, 'apps', name)

  app_config['environments'].each do |environment|
    shared_dir = File.join(app_root, environment, 'shared')

    directory File.join(shared_dir, 'solr') do
      owner app_user
      group app_user
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
  variables(rails_apps: node_root['apps'], rails_user: app_user)
  notifies :restart, 'service[jetty]', :delayed
end
