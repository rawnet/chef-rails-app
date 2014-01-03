#
# Author:: Tom Beynon (tbeynon@rawnet.com) // Dan Upton (dupton@rawnet.com)
# Cookbook Name:: rails_app
# Recipe:: default
#

include_recipe "rails-app::files"
include_recipe "rails-app::web_server"
include_recipe "rails-app::databases"
