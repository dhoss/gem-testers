module ShowPaged
  
  def show_paged
    rubygem = Rubygem.where(name: params[:rubygem_id]).last || Rubygem.where(id: params[:rubygem_id]).last

    conditions = {rubygem_id: rubygem.id}
    conditions.merge!(platform: params[:platform]) if params[:platform]
    
    if params[:version_id]
      v = Version.where(number: params[:version_id], rubygem_id: rubygem.id).first
      conditions.merge!(version_id: v.id)
    end
    
    q = TestResult.where(conditions).includes(:version).includes(:rubygem)
    
    @count = q.count

    filtered_q = q.order("#{TestResult::DATATABLES_COLUMNS[params[:iSortCol_0].to_i]} #{params[:sSortDir_0]}").matching(params[:sSearch])

    @filtered_count = filtered_q.count
    pp filtered_q.offset(params[:iDisplayStart]).limit(params[:iDisplayLength]).to_sql
    @results = filtered_q.offset(params[:iDisplayStart]).limit(params[:iDisplayLength]).all
    
    render json: {iTotalRecords: @count, iTotalDisplayRecords: @filtered_count, aaData: @results.collect(&:datatables_attributes)}
  end
  
end
