class ResourceContextsController < ApplicationController

  def index
    resource_customizations
  end

  # GET /resource_templates/new
  def new
    redirect_to :back and return if params[:requirements_template_id].blank?
    if current_user.has_role?(Role::DMP_ADMIN) && params[:institution_id].blank?
      redirect_to({:action => :choose_institution, :requirements_template_id => params[:requirements_template_id]}) and return
    end
    @req_temp = RequirementsTemplate.find(params[:requirements_template_id])
    redirect_to :back and return if @req_temp.nil?
    @resource_context = ResourceContext.new
    @resource_context.requirements_template_id = @req_temp.id

    #if it is for the template or for a a different institution
    if current_user.has_role?(Role::DMP_ADMIN)
      if params[:institution_id] == "none"
        @resource_context.name = "#{@req_temp.name}"
      else
        that_inst = Institution.find(params[:institution_id])
        @resource_context.name = "#{@req_temp.name} for #{that_inst.name}"
      end
      @required_fields_class = ''
    else
      @resource_context.name = "#{@req_temp.name} for #{current_user.institution.name}"
      @required_fields_class = ' required'
    end

    @resource_context.review_type = "formal_review"

    #the institution_id should be nil if it's none, otherwise set it
    if current_user.has_role?(Role::DMP_ADMIN)
      @resource_context.institution_id = ( params[:institution_id] == "none" ? nil : params[:institution_id])
    else
      @resource_context.institution_id = current_user.institution_id
    end
    @resource_context.contact_email = @req_temp.institution.contact_email
    @resource_context.contact_info = @req_temp.institution.contact_info

    make_institution_dropdown_list
  end

  # GET /resource_templates/edit
  def edit
    @resource_context = ResourceContext.find(params[:id])
    @req_temp = @resource_context.requirements_template
    make_institution_dropdown_list
    customization_resources_list
  end

  def create
    pare_to = ['institution_id', 'requirements_template_id', 'requirement_id', 'resource_id',
              'name', 'contact_info', 'contact_email', 'review_type']
    @resource_context = ResourceContext.new(params['resource_context'].selected_items(pare_to))
    make_institution_dropdown_list

    @req_temp = @resource_context.requirements_template
    message = @resource_context.changed ? 'Customization was successfully created.' : ''

    respond_to do |format|
      if @resource_context.save
        customization_resources_list
        go_to = (params[:after_save] == 'next_page' ? customization_requirement_path(@resource_context.id) :
                        edit_resource_context_path(@resource_context.id))
        format.html { redirect_to go_to, notice: message}
        #format.json { render action: 'edit', status: :created, location: @resource_context }
      else
        format.html { render action: 'new' }
        #format.json { render json: @resource_context.errors, status: :unprocessable_entity }
      end
    end
  end


  def update
    @resource_context = ResourceContext.find(params[:id])
    pare_to = ['institution_id', 'requirements_template_id', 'requirement_id', 'resource_id',
               'name', 'contact_info', 'contact_email', 'review_type']
    to_save = params['resource_context'].selected_items(pare_to)
    message = @resource_context.changed ? 'Customization was successfully updated.' : ''

    make_institution_dropdown_list
    customization_resources_list
    @req_temp = @resource_context.requirements_template

    respond_to do |format|
      if @resource_context.update(to_save)
        go_to = (params[:after_save] == 'next_page' ? customization_requirement_path(@resource_context.id) :
                  edit_resource_context_path(@resource_context.id) )
        format.html { redirect_to go_to, notice: message }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @resource_context.errors, status: :unprocessable_entity }
      end
    end
  end


  def unlink_resource
    #@resource_context = ResourceContext.find(params[:resource_context_to_delete]) 
    @customization_id = params[:customization_id]
    @resource_id = params[:resource_id]
    @template_id = params[:template_id]

    @resource_contexts = ResourceContext.where(resource_id: @resource_id, requirements_template_id: @template_id)

    @resource_contexts.each do |resource_context|
      resource_context.destroy
    end
    
    respond_to do |format|
      format.html { redirect_to edit_customization_resource_path(id: @resource_id, customization_id: @customization_id) }
      format.json { head :no_content }
    end
  end

  def destroy
    @resource_context.destroy
    respond_to do |format|
      format.html { redirect_to resource_contexts_url }
      format.json { head :no_content }
    end
  end

 

  def resource_customizations
    @resource_contexts = ResourceContext.template_level.institutional_level.no_resource_no_requirement.order('name ASC').page(params[:page])
    case params[:scope]
      when "all"
        @resource_contexts 
    
      else
        @resource_contexts = @resource_contexts.per(5)
    end

    unless safe_has_role?(Role::DMP_ADMIN)
      @resource_contexts = @resource_contexts.
                            where(institution_id: [current_user.institution.subtree_ids]).
                            order('name ASC')
    end
  end

  def dmp_for_customization
    select_requirements_template
    @back_to = resource_contexts_path
    @back_text = "Previous page"
    @submit_to = new_resource_context_path
    @submit_text = "Next page"
  end

  def customization_resources_list

    #@customization = ResourceContext.find(params[:id])
    

    @customization = @resource_context
    @customization_institution = current_user.institution

    @template= @customization.requirements_template
    @customization_institution_name = current_user.institution.full_name
    @template_name = @customization.requirements_template.name
    
     
    @resource_contexts = ResourceContext.includes(:resource).
                          per_template(@template).
                          resource_level.where(institution_id: [current_user.institution.subtree_ids])
                                                 
  end

  def choose_institution
    make_institution_dropdown_list

  end

  def select_resource
    
    @template_id = params[:template_id]
    @customization_overview_id = params[:customization_overview_id]

    if safe_has_role?(Role::DMP_ADMIN)

      @resource_contexts = ResourceContext.includes(:resource).
                              where("resource_id IS NOT NULL").
                              order(institution_id: :desc).
                              page(params[:page]).per(20)
    else

      @resource_contexts = ResourceContext.includes(:resource).
                              where("resource_id IS NOT NULL").
                              where(institution_id: [current_user.institution.subtree_ids]).
                              order(institution_id: :desc).
                              group(:resource_id).
                              page(params[:page]).per(20)
    
    end

  end

end
