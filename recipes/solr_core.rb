node_root = node['rails_app']
app_user = node_root['app_user']
jetty_user = node['jetty']['user']

apps_with_solr = node_root['apps'].select { |_, app| app['solr'] }

apps_with_solr.each do |name, app_config|
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

    template File.join(shared_dir, 'config', 'sunspot.yml') do
      source 'sunspot.yml.erb'
      owner app_user
      group app_user
      mode 00755
      variables(environment: environment, port: node['jetty']['port'], path: "#{name}_#{environment}")

      if File.directory? File.join(environment_root, 'current')
        notifies :restart, "service[#{name}_#{environment}_unicorn]", :delayed
      end
    end
  end
end

template File.join(node['solr']['home'], 'solr.xml') do
  owner jetty_user
  group jetty_user
  source 'solr.xml.erb'
  variables(rails_apps: apps_with_solr, rails_user: app_user)
  notifies :restart, 'service[jetty]', :delayed
end
