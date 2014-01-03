node_root = node['rails_app']
app_user = node_root['app_user']

node_root['apps'].each do |name, app_config|
  app_root = File.join('/', 'home', app_user, 'apps', name)

  app_config['environments'].each do |environment|
    environment_root = File.join(app_root, environment)

    # thinking sphinx init script
    template File.join('/', 'etc', 'init.d', "#{name}_#{environment}_thinking_sphinx") do
      source 'thinking_sphinx_init.sh.erb'
      owner 'root'
      group 'root'
      mode 00755
      variables({
        'environment_root' => environment_root,
        'environment'      => environment,
        'rails_user'       => app_user
      })
    end

    # thinking sphinx should run at boot
    service "#{name}_#{environment}_thinking_sphinx" do
      supports :status => true, :restart => true, :reload => true
      action :enable
    end
  end
end
