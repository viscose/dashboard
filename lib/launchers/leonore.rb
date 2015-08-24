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
  name: "provisioning-node-#{nodes.length + i + 1}", 
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
  tries ||= 5
  balancer.ssh ['uptime']
rescue
  sleep 5
  retry unless (tries -= 1).zero?
end

balancer.ssh [
  'sudo -u tomcat7 wget --output-document=/var/lib/tomcat7/webapps/SDGBalancer.war http://dsg.tuwien.ac.at/staff/mvoegler/viscose/leonore/SDGBalancer.war',
  "sleep 5 && curl -i 'http://admin:admin@localhost:8080/manager/text/start?path=/SDGBalancer'",
  # register LEONORE nodes at balancer
  %Q{curl -H "Content-Type: application/json" -X POST -d '{"nodes":["'#{nodes.map { |n| n.private_ip_addresses.first }.join('\'","\'')}'"],"loadThreshold":"'$THRESHOLD'"}' http://localhost:8080/SDGBalancer/balancer/configure}
]

nodes.each do |node|
  cmd = [
    'mkdir -p /tmp/leonore',
    'wget --output-document=/tmp/leonore/component-repository.zip http://www.infosys.tuwien.ac.at/staff/mvoegler/viscose/leonore/component-repository.zip',
    'cd /tmp/leonore && unzip component-repository.zip',
    'sudo chown -R tomcat7:tomcat7 /tmp/leonore',
    'sudo -u tomcat7 wget --output-document=/var/lib/tomcat7/webapps/SDGBuilder.war http://dsg.tuwien.ac.at/staff/mvoegler/viscose/leonore/SDGBuilder.war',
    'sudo -u tomcat7 wget --output-document=/var/lib/tomcat7/webapps/SDGManager.war http://dsg.tuwien.ac.at/staff/mvoegler/viscose/leonore/SDGManager.war',
    "sleep 5 && curl -i 'http://admin:admin@localhost:8080/manager/text/start?path=/SDGBuilder'",
    "curl -i 'http://admin:admin@localhost:8080/manager/text/start?path=/SDGManager'"
  ]
  `ssh-via #{balancer.public_ip_addresses.first} #{node.private_ip_address.first} "#{cmd.join(';')}"`
end

raise 'done?'
