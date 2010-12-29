class TestResultsController < ApplicationController

  protect_from_forgery :except => :create

  def index
    redirect_to rubygem_version_path(params[:rubygem_id].name, params[:version_id])
  end

  def create
    @result = TestResult.new result_attributes
    
    headers['Content-Type'] = 'application/x-yaml'
    render :text => if @result.save
                      Response.new rubygem_version_test_result_url(@result.rubygem, @result.version, @result)
                    else
                      @response = Response.new :fail
                      @result.errors.each { |attribute, errors| errors.each { |e| @response.errors.add(attribute, e) } }
                      @response
                    end.to_yaml
  end

  def show

    @result = TestResult.where(id: params[:id]).first
    @show_output = true

    raise unless @result and @result.rubygem and @result.version

    respond_to do |format|
      format.json { render json: (@result || {}) }
      format.html
    end
  rescue Exception => e
    flash[:notice] = "We could not locate that test result."
    (redirect_to :back rescue redirect_to root_url) and return
  end
  
  private
  
  def result_attributes
    result = YAML::load params[:results]
    attributes = {}
    attributes[:architecture]         = result[:arch]
    attributes[:vendor]               = result[:vendor]
    attributes[:machine_architecture] = result[:machine_arch]
    attributes[:operating_system]     = result[:os]
    attributes[:test_output]          = result[:test_output]
    attributes[:ruby_version]         = result[:ruby_version]
    attributes[:result]               = result[:result]
    attributes[:platform]             = result[:platform]
    
    # TODO: if integrated with gemcutter, the following will be find only, with nil results resulting in some sort of error.
    attributes[:rubygem]              = Rubygem.find_or_create_by_name result[:name]
  
    version_details = {
      :rubygem_id => attributes[:rubygem].id,
      :number     => result[:version][:release],
      :prerelease => result[:version][:prerelease]
    }

    attributes[:version] = Version.where(version_details).first
    attributes[:version] ||= Version.create(version_details)
    
    attributes
  end
end
