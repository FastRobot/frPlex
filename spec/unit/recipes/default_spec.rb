#
# Cookbook Name:: frPlex
# Spec:: default
#
# Copyright (c) 2016 Lamont Lucas, All Rights Reserved.

require 'spec_helper'

describe 'frPlex::default' do
  before do
    stub_command('apt-key list | grep releasedocker').and_return(false)
  end
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu', version: '16.04')
      runner.converge(described_recipe)
    end

    it 'converges successfully' do
      stub_command("zpool list | grep tank").and_return(true)
      stub_command("zfs list | grep docker").and_return(true)
      stub_command('apt-key list | grep releasedocker').and_return(true)
      expect { chef_run }.to_not raise_error
    end
  end
end
