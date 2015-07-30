class VisitorsController < ApplicationController
  def infrastructure
    infrastructure = {
      name: 'ViSCOSe',
      children: [
        {
          name: 'Provisioning',
          children: [
            { 
              name: 'Node 1',
              children: [
                { name: 'IP', value: '128.131.1.1' }
              ]
            },
            { name: 'Node 2' }
          ]
        },
        {
          name: 'Application Deployment',
          children: [
            { name: 'Node 1' }
          ]
        }
      ]
    }
    
    if session[:deployment] && session[:deployment]['num_devices'].to_i > 0 then
      children = []
      session[:deployment]['num_devices'].to_i.times do |i|
        children << { name: "Device #{i + 1}" }
      end
      
      infrastructure[:children] << {
        name: 'Edge Cluster 1',
        children: children
      }
    end
    
    if session[:deployment] && session[:deployment]['apps'].try(:length).to_i > 0 then
      children = []
      
      session[:deployment]['apps'].each do |i|
        children << { name: i }
      end
      
      infrastructure[:children] << {
        name: "Applications",
        children: children
      }
    end
    
    render json: infrastructure
  end
  
  def deploy
    session[:deployment] ||= HashWithIndifferentAccess.new()
    session[:deployment][:num_devices] = params[:num_devices].to_i
    
    redirect_to root_path
  end

  def deploy_app
    session[:deployment] ||= HashWithIndifferentAccess.new()
    session[:deployment][:app_num_devices] = params[:app_num_devices].to_i
    session[:deployment][:apps] ||= []
    session[:deployment][:apps] << params[:app_name]
    session[:deployment][:apps].uniq!
    
    redirect_to root_path
  end
end
