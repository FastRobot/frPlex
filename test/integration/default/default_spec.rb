require 'spec_helper'

docker.containers.where { names == 'plex' }.running?.ids.each do |id|
  describe docker.object(id) do
    its('State.Health.Status') { should eq 'healthy' }
  end
end

describe docker.containers do
  its('names') { should include 'plex' }
  its('names') { should include 'cadvisor' }

    # its('commands') { should_not include '/bin/sh' }
  # its('images') { should_not include 'u12:latest' }
  # its('ports') { should include '0.0.0.0:1234->1234/tcp' }
  # its('labels') { should include 'License=GPLv2,Vendor=CentOS' }
end
