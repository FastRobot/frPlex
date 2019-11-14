name 'frPlex'
maintainer 'Lamont Lucas'
maintainer_email 'lamont@fastrobot.com'
license 'Apache-2.0'
description 'Installs/Configures frPlex'
long_description 'Installs/Configures frPlex'
version '0.2.3'

issues_url 'https://github.com/FastRobot/frPlex/issues'
source_url 'https://github.com/FastRobot/frPlex'

chef_version '>= 12'
%w( debian ubuntu ).each do |os|
  supports os
end
depends 'docker', '~> 4.8'
