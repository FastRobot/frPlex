#
# Cookbook Name:: frPlex
# Recipe:: default
#
# Copyright (c) 2016 Lamont Lucas, All Rights Reserved.

# setup nfs

package 'nfs-common'

directory '/media'

mount '/media' do
  device 'nas.henry.st:/mnt/int/Media'
  fstype 'nfs'
  options 'ro'
  action [:mount, :enable]
end

# setup zfs

package 'zfsutils-linux'
# I manually ran build@docker1:~$ sudo zpool create tank vdb vdc -f

execute 'zpool create tank vdb vdc -f' do
  not_if "zpool list | grep tank"
end

execute 'zfs create -o mountpoint=/var/lib/docker tank/docker' do
  returns [0]
  action :run
  not_if "zfs list | grep docker"
end


# configure docker
package %w(apt-transport-https ca-certificates tmux)

execute 'add docker repo keys' do
  command 'apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D'
  action :run
  not_if "apt-key list | grep releasedocker"
end

file '/etc/apt/sources.list.d/docker.list' do
  content 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
  notifies :run, 'execute[apt refresh]', :immediately
end

execute 'apt refresh' do
  command 'apt-get update'
  action :nothing
end

package 'docker-engine'

docker_service_manager 'default' do
  storage_driver 'zfs'
  action :start
end

# plex containers

docker_volume 'plex-config' do
  action :create
end

docker_volume 'plex-transcode' do
  action :create
end

docker_image 'linuxserver/plex'

docker_container 'plex' do
  repo 'linuxserver/plex'
  env ['VERSION=latest', 'PUID=1023', 'PGID=1023']
  restart_policy 'always'
  network_mode 'host'
  volumes %w(plex-config:/config
           /media/Movies:/data/movies
           /media/TV:/data/tvshows
           /media/HomeMovies:/data/homemovies
           /media/Music:/data/music)
end

# monitor it
docker_image 'google/cadvisor'
docker_image 'prom/node-exporter'

docker_container 'cadvisor' do
  repo 'google/cadvisor'
  restart_policy 'always'
  port '3002:8080'
  volumes
  %w(
    /:/rootfs:ro
    /var/run:/var/run:rw
    /sys:/sys:ro
    /var/lib/docker/:/var/lib/docker:ro
    )
end

docker_container 'node-exporter' do
  repo 'prom/node-exporter'
  port '9100:9100'
  restart_policy 'always'
  network_mode 'host'
end

# plexpy

# backup of important stuff
# https://github.com/biola/chef-zfs_linux has some neat zfs snapshot routines
