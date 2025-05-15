module ActiveHashcash
  class AssetsController < ApplicationController # :nodoc:
    protect_from_forgery except: :show

    Mime::Type.register "image/x-icon", :ico

    def show
      if endpoints.include?(file_name = File.basename(request.path))
        file_path = ActiveHashcash::Engine.root.join / "app/views/active_hashcash/assets" / file_name
        if File.exist?("#{file_path}.erb")
          render(params[:id], mime_type: mime_type)
        else
          render(file: file_path)
        end
        expires_in(1.day, public: true)
      else
        raise ActionController::RoutingError.new
      end
    end

    private

    def endpoints
      return @endpoints if @endpoints
      folder = ActiveHashcash::Engine.root.join("app/views", controller_path)
      files = folder.each_child.map { |path| File.basename(path).delete_suffix(".erb") }
      @endpoints = files.delete_if { |str| str.start_with?("_") }
    end

    def mime_type
      Mime::Type.lookup_by_extension(File.extname(request.path).delete_prefix("."))
    end
  end
end
