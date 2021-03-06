require 'chef/mash'

include GrafanaCookbook::DataSourceApi

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do
  grafana_options = {
    host: new_resource.host,
    port: new_resource.port,
    user: new_resource.admin_user,
    password: new_resource.admin_password
  }
  # If datasource name is not provided as variable,
  # Let's use resource name for it
  unless new_resource.datasource.key?(:name)
    new_resource.datasource[:name] = new_resource.name
  end

  datasources = get_datasource_list(grafana_options)
  exists = false

  datasources.each do |src|
    exists = true if src['name'] == new_resource.datasource[:name]
    break if exists
  end

  # If not found, let's create it
  unless exists
    converge_by("Creating datasource #{new_resource.datasource[:name]}") do
      add_datasource(new_resource.datasource, _legacy_http_semantic, grafana_options)
    end
  end
end

action :update do
  grafana_options = {
    host: new_resource.host,
    port: new_resource.port,
    user: new_resource.admin_user,
    password: new_resource.admin_password
  }
  # If datasource name is not provided as variable,
  # Let's use resource name for it
  unless new_resource.datasource.key?(:name)
    new_resource.datasource[:name] = new_resource.name
  end

  datasources = get_datasource_list(grafana_options)
  exists = false

  # Check wether we have to update datasource's login
  if new_resource.datasource[:name] != new_resource.name
    old_name = new_resource.name
  else
    old_name = new_resource.datasource[:name]
  end

  # Find wether datasource already exists
  # If found, update all informations we have to
  datasources.each do |src|
    if src['name'] == old_name
      exists = true
      new_resource.datasource[:id] = src['id']
      converge_by("Updating datasource #{new_resource.datasource[:name]}") do
        update_datasource(new_resource.datasource, _legacy_http_semantic, grafana_options)
      end
    end
    break if exists
  end
end

action :delete do
  grafana_options = {
    host: new_resource.host,
    port: new_resource.port,
    user: new_resource.admin_user,
    password: new_resource.admin_password
  }
  # If datasource name is not provided as variable,
  # Let's use resource name for it
  unless new_resource.datasource.key?(:name)
    new_resource.datasource[:name] = new_resource.name
  end

  datasources = get_datasource_list(grafana_options)
  exists = false

  # Find wether datasource already exists
  # If found, delete it
  datasources.each do |src|
    if src['name'] == new_resource.datasource[:name]
      exists = true
      new_resource.datasource[:id] = src['id']
      converge_by("Deleting data source #{new_resource.name}") do
        delete_datasource(new_resource.datasource, grafana_options)
      end
    end
  end
end

def _legacy_http_semantic
  return false if node['grafana']['version'] == 'latest'
  Gem::Version.new(node['grafana']['version']) < Gem::Version.new('2.0.3')
end
