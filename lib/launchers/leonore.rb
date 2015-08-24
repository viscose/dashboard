LEONORE_BASE_IMAGE_ID = '03f4725b-118e-456c-886c-b3a62bac7fc5'
NUM_NODES = 2

#TODO: Set SSH key, install application war via cloud-init
user_data = %Q{#cloud-config
ssh_import_id: [inzinger]
apt_proxy: http://robot-devil.infosys.tuwien.ac.at:8000/
packages:
 - htop
}

balancer = Server.find_by_role(:leonore_master).try(:first).try(:fog_server) || compute_client.servers.create(
  name: 'provisioning-balancer', 
  image_ref: LEONORE_BASE_IMAGE_ID, 
  flavor_ref: '000000512',
  user_data: user_data
)

nodes = Server.find_by_role(:leonore_node).map(&:fog_server) || []
(NUM_NODES - nodes.length).times do |i|
  nodes << compute_client.servers.create(
  name: "provisioning-node-#{nodes.length + 1}",
  image_ref: LEONORE_BASE_IMAGE_ID, 
  flavor_ref: '000000512',
  user_data: user_data
)
end

balancer.wait_for { ready? }
balancer.reload

unless Server.new(balancer).public_address
  # Set instance roles
  balancer.metadata.set(role: :leonore_master)
  nodes.each { |n| n.metadata.set(role: :leonore_node) }

  # Add public IP to balancer
  balancer.associate_address compute_client.addresses.select { |a| a.instance_id == nil }.first.ip
end

balancer.username = 'ubuntu'
begin
  tries ||= 10
  balancer.ssh ['uptime']
rescue
  sleep 5
  balancer.reload
  retry unless (tries -= 1).zero?
end

nodes.map(&:reload)
balancer.ssh [
  'sudo -u tomcat7 wget --output-document=/tmp/SDGBalancer.war http://dsg.tuwien.ac.at/staff/mvoegler/viscose/leonore/SDGBalancer.war && sudo -u tomcat7 mv /tmp/SDGBalancer.war /var/lib/tomcat7/webapps',
  "while ! curl -i 'http://admin:admin@localhost:8080/manager/text/list'|grep 'SDGBalancer:running'; do sleep 1; echo waiting; done",
  # register LEONORE nodes at balancer
  %Q{curl -H "Content-Type: application/json" -X POST -d '{"nodes":["'#{nodes.map(&:private_ip_address).join('\'","\'')}'"],"loadThreshold":"25"}' http://localhost:8080/SDGBalancer/balancer/configure}
]

nodes.each do |node|
  node.wait_for { ready? }
  node.reload
  cmd = [
    'mkdir -p /tmp/leonore',
    'wget --output-document=/tmp/leonore/component-repository.zip http://www.infosys.tuwien.ac.at/staff/mvoegler/viscose/leonore/component-repository.zip',
    'cd /tmp/leonore && unzip component-repository.zip',
    'sudo chown -R tomcat7:tomcat7 /tmp/leonore',
    'sudo -u tomcat7 wget --output-document=/tmp/SDGBuilder.war http://dsg.tuwien.ac.at/staff/mvoegler/viscose/leonore/SDGBuilder.war',
    'sudo -u tomcat7 wget --output-document=/tmp/SDGManager.war http://dsg.tuwien.ac.at/staff/mvoegler/viscose/leonore/SDGManager.war',
    'sudo -u tomcat7 mv /tmp/*.war /var/lib/tomcat7/webapps'
  ]
  `ssh-via #{balancer.public_ip_address} #{node.private_ip_address} "#{cmd.join(';')}"`
end

raise 'done?'
