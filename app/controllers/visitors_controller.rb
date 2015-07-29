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
    
    if session[:deployment] then
      children = []
      session[:deployment]['num_devices'].to_i.times do |i|
        children << { name: "Device #{i + 1}" }
      end
      
      infrastructure[:children] << {
        name: 'Edge Cluster 1',
        children: children
      }
      # raise 'asdf'
    end
    
    render json: infrastructure
  end
  
  def deploy
    unless params[:num_devices].to_i == 0
      session[:deployment] = HashWithIndifferentAccess.new({
        num_devices: params[:num_devices]
      })
    else
      session[:deployment] = nil
    end
    
    redirect_to root_path
  end
end
