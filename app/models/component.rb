class Component
  include ActiveModel::Model
  include GlobalID::Identification
  mattr_accessor :logger, instance_writer: false
  
  attr_reader :id, :name, :description, :url, :path, :spec_path, :steps, :params
  
  def self.root
    Rails.root + 'lib/components'
  end
  
  def self.all
    components = []
    Dir[root + '*'].each do |path|
      components << Component.new(path)
    end
    components
  end
  
  def self.find(id)
    Component.new(root + id.to_s)
  end
  
  def initialize(path)
    @spec_path = File.join(path, 'viscose.yml')
    raise ArgumentError, "Component at '#{path}' must provide definition in viscose.yml" unless File.exist?(spec_path)

    @path = Pathname.new(path)
    spec = YAML.load_file(spec_path)
    @id = File.basename(path)
    @name = spec['name']
    @description = spec['description']
    @url = spec['url']
    @deployment_steps = spec['deploy']
    @undeployment_steps = spec['undeploy']
    @params = spec['params']
    @steps = {}
    spec['steps'].each do |s|
      step = ProvisioningStep.new(s, self)
      @steps[step.name] = step
    end
  end
  
  def initiate_deployment(steps: steps)
    DeployComponentJob.perform_later(self, steps)
  end
  
  def deploy(step_names: @deployment_steps)
    raise ArgumentError, 'Specify Array of step names.' unless step_names.is_a? Array
    deployment_id = SecureRandom.uuid
    logger.info { "Starting deployment #{deployment_id} for #{name} with #{step_names.inspect}." }
    deployment_steps = steps.select do |step_name, step|
      step_names.include?(step_name)
    end.values
    deployment_steps.each(&:provision)
  end

  def undeploy
    deploy(step_names: @undeployment_steps)
  end
  
  def deployment_status
    statuses = {}
    steps.values.select(&:has_verification?).map do |step|
      statuses[step.name] = step.already_executed?
    end
    statuses
  end
  
  def deployment_steps_upto(step_name)
    raise ArgumentError, "Unknown step #{step_name}" unless @deployment_steps.include? step_name
    @deployment_steps.take_while { |s| s != step_name } << step_name
  end
  
  def ==(other)
    other.is_a?(Component) && path == other.path
  end
  
  def to_param
    id
  end
end

class ProvisioningStep
  mattr_accessor :logger, instance_writer: false
  attr_reader :name, :component

  def self.logger; Rails.logger end
  
  def initialize(step_definition, component)
    @component = component
    
    parse_step_definition(step_definition)
    validate_step_definition
  end
  
  def provision
    execute_step unless already_executed?
  end
  
  def already_executed?
    execute_step_verification rescue false
  end
  
  def execute_step
    script = @script || File.open(@script_file).read
    script_file = @script_file || @component.spec_path
    binding.eval(script, script_file.to_s)
  end
  
  def execute_step_verification
    if has_verification?
      script = @verify_script || File.open(@verify_script_file).read
      script_file = @verify_script_file || @component.spec_path
      binding.eval(script, script_file.to_s)
    else
      false
    end
  end
  
  def valid?
    validate_step_definition rescue false
  end
  
  def has_verification?
    @verify_script || @verify_script_file && File.exist?(@verify_script_file)
  end
  
  private
  def parse_step_definition(step_definition)
    if step_definition.is_a? Hash
      @name = step_definition['name']
      @script = step_definition['script']
      @script_file = step_definition['script_file']
      @verify_script = step_definition['verify']
      @verify_script_file = step_definition['verify_file']
    elsif step_definition.is_a? String
      @name = step_definition
    end
    
    @script_file ||= @component.path + "#{@name}.rb" unless @script
    @verify_script_file ||= @component.path + "#{@name}_verify.rb" unless @verify_script
  end

  
  def validate_step_definition
    @script || File.open(@script_file)
  end  

  def compute_client
    Server.compute_client
  end
  
  def params
    component.params
  end
end

