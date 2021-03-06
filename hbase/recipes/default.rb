#
# Cookbook Name:: hbase
# Recipe:: default
#
# Copyright 2011, Happy-Camper Street
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "hadoop"
include_recipe "zookeeper"

group "hbase" do
  gid 204
end

user "hbase" do
  uid "204"
  gid "hbase"
  comment "HBase"
  home "/var/run/hbase"
  shell "/sbin/nologin"
end

group "hadoop" do
  members ["hbase"]
  append true
end

package "hadoop-hbase" do
  version node[:hbase][:version]
#  action :upgrade
end

template "/etc/hbase/conf/hbase-env.sh" do
  source "hbase-env.sh.erb"
  mode "0644"

  variables( :heapsize => node[:hbase][:heapsize] )
end

cookbook_file "/etc/hbase/conf/hadoop-metrics.properties" do
  source "hadoop-metrics.properties"
  mode "0644"
end

template "/etc/hbase/conf/hbase-site.xml" do
  source "hbase-site.xml.erb"
  mode "0644"

  variables( :namenode     => search(:node, 'role:NameNode')[0],
             :namenodeport => node[:hadoop][:core][:namenodeport],
             :hbasetmpdir  => node[:hbase][:tmp][:dir],
             :zookeepers   => search(:node, 'role:ZooKeeper').sort_by { |zk| zk[:hostname] } )
end

template "/etc/hbase/conf/regionservers" do
  source "regionservers.erb"
  mode "0644"

  variables( :regionservers => search(:node, 'role:RegionServer').sort_by { |rs| rs[:hostname] } )
end


link "/usr/lib/hbase/lib/hadoop-lzo-#{node[:hadoop][:lzo][:version]}.jar" do
  to "/usr/lib/hadoop-0.20/lib/hadoop-lzo-#{node[:hadoop][:lzo][:version]}.jar"
  only_if "test -f /usr/lib/hadoop-0.20/lib/hadoop-lzo-#{node[:hadoop][:lzo][:version]}.jar"
end

link "/usr/lib/hbase/lib/native" do
  to "/usr/lib/hadoop-0.20/lib/native"
end
