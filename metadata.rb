name             'rails-app'
maintainer       'Rawnet'
maintainer_email 'tbeynon@rawnet.com'
license          'All rights reserved'
description      'Creates Rails application files'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.16'
depends          "build-essential"
depends          "database"
depends          "hostsfile"
depends          "monit"
suggests         "mysql"
suggests         "postgresql"
