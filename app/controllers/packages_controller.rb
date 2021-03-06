require File.expand_path('../../../lib/exceptions/template_error.rb', __FILE__)
class PackagesController < DataFilesController

  expose(:access_rights) { AccessRightsLookup.new.access_rights }
  expose(:experiment_access_rights) {
    Experiment.all.map { |experiment|
      access_rights_id = AccessRightsLookup.new.get_id(experiment.access_rights)
      {:id => experiment.id, :access_rights_id => access_rights_id, :access_rights_url => AccessRightsLookup.new.get_url(access_rights_id) } }
  }

  def new
    if !current_user.cart_items.empty?
      package_size = current_user.cart_items.sum(:file_size)
      max_package_size = SystemConfiguration.instance.max_package_size_bytes
      if max_package_size >= 0 && package_size > max_package_size
        if request.referer.nil?
          redirect = root_path
        else
          redirect = request.referer
        end
        redirect_to redirect, alert: 'Cannot create package. Total size of files in the cart exceeds the maximum package size.'
        return
      end
      @back_request = request.referer
      @package = Package.new
      @package.set_times(current_user)
      @package.set_metatdata
      set_tab :dashboard, :contentnavigation
    end
  end

  def edit
    @package = Package.find(params[:id])
  end

  def create
    package_params = params[:package]
    @package = Package.create_package(package_params, params[:date], current_user)
    @package.related_website_list = package_params[:related_website_list] if package_params[:related_website_list]
    if @package.save
      save_tags(@package, params[:tags])
      data_file_ids = current_user.cart_item_ids
      @package.label_list = package_params[:label_list] if package_params[:label_list]
      @package.grant_number_list = package_params[:grant_number_list] if package_params[:grant_number_list]
      @package.parent_ids = data_file_ids
      begin
        if params[:run_in_background]
          # Persist the job id in the db - we need to retrieve it per record basis
          @package.uuid = PackageWorker.create({:package_id => @package.id, :data_file_ids => data_file_ids, :user_id => current_user.id})
          @package.save
          redirect_to data_file_path(@package), notice: 'Package is now queued for processing in the background.'
        else
          # Run normally
          CustomDownloadBuilder.bagit_for_files_with_ids(data_file_ids, @package) do |zip_file|
            attachment_builder = AttachmentBuilder.new(APP_CONFIG['files_root'], current_user, FileTypeDeterminer.new, MetadataExtractor.new)
            package = attachment_builder.build_package(@package, zip_file)
            build_rif_cs(package, @package) unless package.nil?
          end
          @package.mark_as_complete
          redirect_to data_file_path(@package), notice: 'Package was successfully created.'
        end

      rescue ::TemplateError => e
        logger.error e.message
        redirect_to data_file_path(@package), alert: 'There were errors in the README.html template file.'
      end

    else
      @package.reformat_on_error(package_params[:filename], params[:tags], params[:label_list], params[:grant_number_list])
      render :action => 'new'
    end
  end

  def api_create
    errors = []
    warnings = []

    file_ids = params[:file_ids]
    tag_names = params[:tag_names]
    label_names = params[:label_names]
    grant_numbers = params[:grant_numbers]
    params[:experiment_id] = params[:org_level2_id] || params[:experiment_id]
    params[:file_processing_description] = params[:description]
    run_in_background = params[:run_in_background].nil? ? true : params[:run_in_background].to_bool
    include_invalid_content = params[:force].nil? ? false : params[:force].to_bool

    data_files = validate_file_ids(file_ids, current_user, errors, warnings, include_invalid_content)
    tag_ids = parse_tags(tag_names, errors)
    label_ids = parse_labels(label_names, errors)
    grant_number_ids = parse_grant_numbers(grant_numbers, errors)

    params[:license] = AccessRightsLookup.new.get_url(params[:license])

    package = Package.create_package(params, nil, current_user)
    if errors.empty? && package.save
      save_tags(package, tag_ids)
      save_labels(package, label_ids)
      save_grant_numbers(package, grant_number_ids)

      data_file_ids = data_files.map { |data_file| data_file.id }
      package.label_list = params[:label_list] if params[:label_list]
      package.parent_ids = data_file_ids

      begin
        if run_in_background
          package.uuid = PackageWorker.create({:package_id => package.id, :data_file_ids => data_file_ids, :user_id => current_user.id})
          package.save
          messages = ['Package is now queued for processing in the background.']
          messages += warnings unless warnings.empty?
          render :json => {package_id: package.id, :messages => messages, :file_name => package.filename, :file_type => package.file_processing_status}
        else
          CustomDownloadBuilder.bagit_for_files_with_ids(data_file_ids, package) do |zip_file|
            attachment_builder = AttachmentBuilder.new(APP_CONFIG['files_root'], current_user, FileTypeDeterminer.new, MetadataExtractor.new)
            new_package = attachment_builder.build_package(package, zip_file)
            build_rif_cs(new_package, package) unless new_package.nil?
          end
          package.mark_as_complete
          messages = ['Package was successfully created.']
          messages += warnings unless warnings.empty?
          render :json => {package_id: package.id, :messages => messages, :file_name => package.filename, :file_type => package.file_processing_status}
        end
      rescue ::TemplateError => e
        logger.error e.message
        render :json => {:messages => ['There were errors in the README.html template file']}, :status => :internal_server_error
      end
    else
      package.errors.each{ |attribute,message|
        errors << "#{attribute} #{message}"
      }
      render :json => {:messages => errors}, :status => :bad_request
    end
  end

  def publish
    begin
      valid = false
      unless @package.nil?
        if @package.published.eql?(true)
          redirect_to data_files_path, :notice => "This package is already submitted for publishing."
        else
          if @package.save! and publish_rif_cs(@package)
              @package.set_to_published(current_user)
              valid = true
          end
        end
      end
    rescue Errno::ENOENT => e
      Rails.logger.error e
      valid = false
    end

    redirect_to data_files_path, :notice => valid ? "Package has been successfully submitted for publishing." : "Unable to publish package."
  end

  def api_publish
    package_id = params[:package_id]
    if package_id.blank?
      render :json => {:messages => ['package_id is required']}, :status => :bad_request
      return
    end

    if !Package.exists?(package_id)
      render :json => {:messages => ["Package with id #{package_id} could not be found"]}, :status => :bad_request
      return
    end

    package = Package.find(package_id)

    config = SystemConfiguration.instance
    email_level = config.email_level.nil? ? "Always" : config.email_level
    recipients = config.research_librarians_list << package.created_by.email
    if package.published?
      render :json => {:package_id => package.id, :messages => ["Package #{package_id} is already submitted for publishing."]}
      return
    end

    if package.save! and publish_rif_cs(package)
      package.set_to_published(current_user)
      Notifier.notify_recipients_of_successful_package_publish(package, recipients).deliver unless email_level.eql?("Failure only")
      render :json => {:package_id => package.id, :messages => ["Package has been successfully submitted for publishing."]}
    else
      Notifier.notify_recipients_of_failed_package_publish(package, recipients).deliver unless email_level.eql?("Success only")
      render :json => {:messages => ["Unable to publish package."]}
    end
  end

  private

  # DC21-603 - inheritance and HABTM duplicates records. Will need to fix associations up later.
  def save_tags(package, tags)
    pkg = DataFile.find(package.id)
    pkg.tag_ids = tags
    pkg.save
  end

  def save_labels(package, labels)
    pkg = DataFile.find(package.id)
    pkg.label_ids = labels
    pkg.save
  end

  def save_grant_numbers(package, grant_numbers)
    pkg = DataFile.find(package.id)
    pkg.grant_number_ids = grant_numbers
    pkg.save
  end


  def build_rif_cs(files, package)
    #build the rif-cs and place in the unpublished_rif_cs folder, where it will stay until published in DC21
    dir = APP_CONFIG['unpublished_rif_cs_directory']
    Dir.mkdir(dir) unless Dir.exists?(dir)
    output_location = File.join(dir, "rif-cs-#{package.id}.xml")

    file = File.new(output_location, 'w')

    options = {:root_url => root_url,
               :collection_url => data_file_path(package),
               :zip_url => download_data_file_url(package),
               :submitter => current_user}
    RifCsGenerator.new(PackageRifCsWrapper.new(package, files, options), file).build_rif_cs
    file.close
  end

  def publish_rif_cs(package)
    #TODO set new 'submitter' value
    dir = APP_CONFIG['published_rif_cs_directory']
    unpublished_dir = APP_CONFIG['unpublished_rif_cs_directory']
    Dir.mkdir(dir) unless Dir.exists?(dir)
    output_location = File.join(dir, "rif-cs-#{package.id}.xml")
    unpublished_location = File.join(unpublished_dir, "rif-cs-#{package.id}.xml")
    FileUtils.mv(unpublished_location, output_location)
    true
  end

  def validate_file_ids(file_ids, current_user, errors, warnings, include_invalid_content)
    data_files = []
    if !file_ids.is_a? Array
      errors << 'file_ids is required and must be an Array'
      return data_files
    end
    if file_ids.empty?
      errors << 'file_ids can\'t be empty'
      return data_files
    end

    file_ids.each do |file_id|
      begin
        id_as_int = Integer(file_id)
        if !DataFile.exists?(id_as_int)
          errors << "file with id '#{file_id}' could not be found"
        else
          data_file = DataFile.find(id_as_int)
          if (data_file.is_package? && Package.find(id_as_int).is_incomplete_package?) || data_file.is_error_file?
            if !include_invalid_content
              errors << "file '#{file_id}' is not in a state that can be packaged"
            else
              data_files << data_file
              status = data_file.is_package? ? data_file.transfer_status : data_file.file_processing_status
              warnings << "Warning: file '#{file_id}' is in state '#{status}'"
            end
          elsif data_file.is_authorised_for_access_by?(current_user)
            data_files << data_file
          else
            errors << "unauthorized to package file '#{file_id}'"
          end
        end
      rescue ArgumentError
        errors << "file id '#{file_id}' is not a valid file id"
      end
    end

    package_size = data_files.sum(&:file_size)
    max_package_size = SystemConfiguration.instance.max_package_size_bytes
    if max_package_size >= 0 && package_size > max_package_size
      errors << 'total size of files exceeds the maximum package size'
    end

    return data_files.uniq
  end

end
