Server.all.each do |server|
  server.destroy! unless server.role == :viscose_dashboard
end