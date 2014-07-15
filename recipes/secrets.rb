app_user = node['rails_app']['app_user']
node_root = node['rails_app']

node_root['apps'].each do |name, config|
  data_bag_stuff = data_bag_item('rails_app', name)

  config['environments'].each do |environment, _|
    root = File.join('/', 'home', app_user, 'apps', name, environment)
    secrets = data_bag_stuff[environment]['secrets.yml']

    file File.join(root, 'shared', 'config', 'secrets.yml') do
      content({ environment => secrets }.to_yaml)

      owner app_user
      group app_user
      mode 00755
      notifies :restart, "service[#{name}_#{environment}_unicorn]", :delayed
    end
  end
end
