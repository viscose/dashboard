require 'fog'
require 'ipaddr'

class Server
  include ActiveModel::Model
  
  attr_reader :id, :name, :role, :status
  attr_reader :private_address, :public_address, :fog_server
  
  def self.compute_client
    @compute_client ||= Fog::Compute.new(
      provider: :openstack,
      openstack_api_key: ENV['OS_PASSWORD'],
      openstack_username: ENV['OS_USERNAME'],
      openstack_auth_url: ENV['OS_AUTH_URL'] + '/tokens',
      openstack_tenant: ENV['OS_TENANT_NAME']
    )
  end
  
  def compute_client
    self.class.compute_client
  end
  
  def self.all
    compute_client.servers.map { |s| Server.new(s) }
  end
  
  def self.find(id)
    Server.new(compute_client.servers.get(id))
  end
  
  def self.find_by_role(role)
    all.select { |s| s.role == role.to_s }
  end
  
  def initialize(fog_server)
    @id = fog_server.id
    @name = fog_server.name
    @role = fog_server.metadata.get(:role).value rescue nil
    @private_address = fog_server.private_ip_address
    @public_address = fog_server.floating_ip_address
    @status = fog_server.os_ext_sts_task_state || fog_server.os_ext_sts_vm_state
    @fog_server = fog_server
  end
  
  def destroy!
    compute_client.delete_server(id)
  end
  
  def to_param
    id
  end
end
