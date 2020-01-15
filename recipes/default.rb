#
# Cookbook Name:: frPlex
# Recipe:: default
#

# setup nfs

package 'nfs-common'

directory '/media'

mount '/media' do
  device node['frPlex']['media']['nfs']
  fstype 'nfs'
  options 'rw'
  action [:mount, :enable]
  only_if { node['frPlex']['mount_nfs'] }
end

directory '/etc/systemd/system/docker.service.d' do
  recursive true
end

cookbook_file '/etc/systemd/system/docker.service.d/remote-fs.conf' do
  notifies :run, 'execute[systemctl daemon-reload]'
end

execute 'systemctl daemon-reload' do
  action :nothing
end

# setup zfs

package 'zfsutils-linux'
# I manually ran build@docker1:~$ sudo zpool create tank vdb vdc -f

execute 'zpool create tank vdb vdc -f' do
  not_if 'zpool list | grep tank'
  only_if { node['frPlex']['manage_zfs'] }
end

execute 'zfs create -o mountpoint=/var/lib/docker tank/docker' do
  returns [0]
  action :run
  not_if 'zfs list | grep docker'
  only_if { node['frPlex']['manage_zfs'] }
end

# configure docker
package %w(apt-transport-https ca-certificates tmux)

execute 'add docker repo keys' do
  command 'apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D'
  action :run
    not_if 'apt-key list | grep releasedocker'
end

file '/etc/apt/sources.list.d/docker.list' do
  content 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
  notifies :run, 'execute[apt refresh]', :immediately
end

execute 'apt refresh' do
  command 'apt-get update'
  action :nothing
end

package 'docker-ce'

docker_service_manager 'default' do
  # storage_driver 'zfs'
  action :start
end

# plex containers

docker_volume 'plex-config' do
  action :create
end

docker_volume 'plex-transcode' do
  action :create
end

docker_image 'plexinc/pms-docker' do
  tag 'plexpass'
end

docker_container 'plex' do
  repo 'plexinc/pms-docker'
  tag 'plexpass'
  env ['VERSION=latest', 'PLEX_UID=1023', 'PLEX_GID=1023']
  restart_policy 'always'
  network_mode 'host'
  volumes %w(plex-config:/config
             plex-transcode:/transcode
             /media/Movies:/data/movies
             /media/TV:/data/tvshows
             /media/HomeMovies:/data/homemovies
             /media/Music:/data/music
             /media/Cartoons:/data/cartoons)
end

# monitor it
docker_image 'google/cadvisor'

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

# plexpy

# backup of important stuff
# https://github.com/biola/chef-zfs_linux has some neat zfs snapshot routines

# general auto-zfs snapshot scripts would be fine
# hidden directory under /var/lib/docker/.zfs/ has snapshots/
# /var/lib/docker/.zfs/snapshot/20160925/volumes/plex-config/_data

# root@docker1 /v/l/d/.z/s/2/v/p/_data# rsync -a --progress --exclude=Cache/ Library user@somewhere:tmp/
