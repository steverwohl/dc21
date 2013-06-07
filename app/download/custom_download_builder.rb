require 'bagit'

class CustomDownloadBuilder

  def self.zip_for_files(data_files, &block)
    temp_dir = Dir.mktmpdir
    zip_file_path = Dir::Tmpname.make_tmpname("/tmp/download_zip", nil)
    begin
      file_details = data_files.collect { |df| [df.filename, df.path] }

      ZipBuilder.build_simple_zip_from_files(zip_file_path, file_details)
      File.chmod(00644, zip_file_path)
      block.yield(File.new(zip_file_path))
    ensure
      FileUtils.remove_entry_secure temp_dir
    end
  end


  def self.bagit_for_files_with_ids(ids, pkg, &block)
    temp_dir = Dir.mktmpdir
    zip_file = Tempfile.new("download_zip")

    begin
      bag = BagIt::Bag.new temp_dir
      readme_path = File.join(bag.data_dir, "README.html")

      data_files = DataFile.find(ids)
      data_files.each do |data_file|
        temp_path = File.join(bag.data_dir,  data_file.filename)
        FileUtils.cp data_file.path, temp_path
        temp_path
      end

      readme_html = MetadataWriter.generate_metadata_for(data_files, pkg)
      File.open(readme_path, 'w+') { |f| f.write(readme_html) }

      bag.manifest!

      ZipBuilder.build_zip(zip_file, Dir["#{temp_dir}/*"])
      block.yield(zip_file)
    ensure
      zip_file.close
      zip_file.unlink
      FileUtils.remove_entry_secure temp_dir
    end
  end


end
