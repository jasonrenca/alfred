Alfred::App.controllers :assignment_file, :parent => :assignments do
  
  get :index do
    @assignment = Assignment.find(params[:assignment_id])
    @files = @assignment.assignment_files || [ ]
    render 'assignment_files/index'
  end

  get :new do
    @title = t('assignments.files.new.title')
    @assignment = Assignment.find(params[:assignment_id])
    @file = AssignmentFile.new(:assignment => @assignment)
    render 'assignment_files/new'
  end

  post :create do
    file_io = params[:assignment_file]['file']
    @assignment = Assignment.find(params[:assignment_id])
    @assignment_file = AssignmentFile.new(:assignment => @assignment, :name => file_io[:filename])

    storage_gateway = Storage::StorageGateways.get_gateway
    storage_gateway.upload(@assignment_file.path, file_io[:tempfile])    
    
    if @assignment_file.save
      redirect url(:assignment, :file, :index, :assignment_id => params[:assignment_id])
    else
      @title = t('assignments.files.new.title')
      flash.now[:error] = pat(:create_error, :model => 'assignment_file')
      render 'assignment_files/new'
    end
  end

  delete :destroy, :with => :id do
    assignment_file = AssignmentFile.get(params[:id].to_i)
    if assignment_file
      assignment_file.transaction do |tx|
        begin
          file_path = assignment_file.path
          record_deleted = assignment_file.destroy

          if record_deleted
            storage_gateway = Storage::StorageGateways.get_gateway
            storage_gateway.delete(file_path)

            flash[:success] = pat(:delete_success, :model => 'AssignmentFile', :id => "#{params[:id]}")
          else
            flash[:error] = pat(:delete_error, :model => 'AssignmentFile')
          end
        rescue Storage::FileDeleteError => e
          tx.rollback
        end
      end
      
      redirect url(:assignment, :file, :index, :assignment_id => params[:assignment_id])
    else
      flash[:warning] = pat(:delete_warning, :model => 'AssignmentFile', :id => "#{params[:id]}")
      halt 404
    end
  end
end