module Paperclip
  module ImageMagickVersionDetector
    # Returns :im7, :im6, or nil (not installed)
    def self.detected_version
      @detected_version = detect! unless defined?(@detected_version)
      @detected_version
    end

    # Returns true if ImageMagick 7 is in use (either detected or forced via config)
    def self.imagemagick7?
      version = Paperclip.options[:imagemagick_version]
      case version
      when :im7 then true
      when :im6 then false
      else detected_version == :im7
      end
    end

    # Returns the correct binary for "convert" operations.
    # IM6: "convert", IM7: "magick"
    def self.convert_command
      imagemagick7? ? "magick" : "convert"
    end

    # Returns the correct binary for "identify" operations.
    # IM6: "identify", IM7: "magick identify"
    def self.identify_command
      imagemagick7? ? "magick identify" : "identify"
    end

    # Clears cached detection result. Useful for tests.
    def self.reset!
      remove_instance_variable(:@detected_version) if defined?(@detected_version)
    end

    private

    def self.detect!
      configure_command_path!

      # Try IM7 first: `magick -version`
      begin
        output = Terrapin::CommandLine.new("magick", "-version", swallow_stderr: true).run
        return :im7 if output.to_s.include?("ImageMagick")
      rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError
        # IM7 not found, try IM6
      end

      # Try IM6: `convert -version`
      begin
        output = Terrapin::CommandLine.new("convert", "-version", swallow_stderr: true).run
        return :im6 if output.to_s.include?("ImageMagick")
      rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError
        # IM6 not found either
      end

      nil
    end

    def self.configure_command_path!
      command_path = Paperclip.options[:command_path]
      return unless command_path

      terrapin_path_array = Terrapin::CommandLine.path.try(:split, Terrapin::OS.path_separator)
      Terrapin::CommandLine.path = [terrapin_path_array, command_path].flatten.compact.uniq
    end
  end
end
