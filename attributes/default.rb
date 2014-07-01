default['rails_app']['apps'] = []
default['rails_app']['admin_user'] = 'admin'
default['rails_app']['rails_user'] = 'rails'

default['rails_app']['mysql']['host'] = 'localhost'
default['rails_app']['mysql']['username'] = 'root'
default['rails_app']['mysql']['password'] = node['mysql']['server_root_password']
