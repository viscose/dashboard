class ServersController < ApplicationController  
  def index
    @servers = Server.all
  end
  
  def destroy
    @server = Server.find(params[:id])
    @server.destroy!
    
    respond_to do |format|
      format.html { redirect_to servers_url }
      format.json { head :no_content }
    end
  end
  
  def launch
    app = params[:app]
    
    launcher_path = File.join(Rails.root, 'lib', 'launchers', "#{app}.rb")
    unless File.exists?(launcher_path)
      flash[:error] = "Cannot launch #{app}"
      raise LauncherNotFoundError.new
    end
    
    compute_client = Server.compute_client
    binding.eval(File.open(launcher_path).read, launcher_path)
    
    flash[:notice] = "launching #{app}"
    respond_to do |format|
      format.html { redirect_to servers_url }
      format.json { head :no_content }
    end
  end
end
