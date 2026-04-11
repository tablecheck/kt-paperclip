require "spec_helper"

describe Paperclip::ImageMagickVersionDetector do
  before do
    @original_imagemagick_version = Paperclip.options[:imagemagick_version]
    @original_command_path = Paperclip.options[:command_path]
  end

  after do
    described_class.reset!
    Paperclip.options[:imagemagick_version] = @original_imagemagick_version
    Paperclip.options[:command_path] = @original_command_path
  end

  describe ".detected_version" do
    context "when ImageMagick 7 is installed" do
      before do
        im7_cmd = double(run: "Version: ImageMagick 7.1.1-38 Q16-HDRI x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", swallow_stderr: true)
          .and_return(im7_cmd)
      end

      it "returns :im7" do
        expect(described_class.detected_version).to eq(:im7)
      end

      it "does not try convert" do
        expect(Terrapin::CommandLine).not_to receive(:new)
          .with("convert", "-version", anything)
        described_class.detected_version
      end
    end

    context "when only ImageMagick 6 is installed" do
      before do
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", swallow_stderr: true)
          .and_raise(Terrapin::CommandNotFoundError.new("magick"))

        im6_cmd = double(run: "Version: ImageMagick 6.9.12-98 Q16 x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("convert", "-version", swallow_stderr: true)
          .and_return(im6_cmd)
      end

      it "returns :im6" do
        expect(described_class.detected_version).to eq(:im6)
      end
    end

    context "when magick -version exits with non-zero status" do
      before do
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", swallow_stderr: true)
          .and_raise(Terrapin::ExitStatusError.new("magick"))

        im6_cmd = double(run: "Version: ImageMagick 6.9.12-98 Q16 x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("convert", "-version", swallow_stderr: true)
          .and_return(im6_cmd)
      end

      it "falls back to IM6" do
        expect(described_class.detected_version).to eq(:im6)
      end
    end

    context "when ImageMagick is not installed at all" do
      before do
        allow(Terrapin::CommandLine).to receive(:new)
          .and_raise(Terrapin::CommandNotFoundError.new("not found"))
      end

      it "returns nil" do
        expect(described_class.detected_version).to be_nil
      end
    end

    context "when a non-ImageMagick 'magick' binary exists" do
      before do
        non_im_cmd = double(run: "Some Other Program v1.0")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("magick", "-version", swallow_stderr: true)
          .and_return(non_im_cmd)

        im6_cmd = double(run: "Version: ImageMagick 6.9.12-98 Q16 x86_64")
        allow(Terrapin::CommandLine).to receive(:new)
          .with("convert", "-version", swallow_stderr: true)
          .and_return(im6_cmd)
      end

      it "falls through to IM6 detection" do
        expect(described_class.detected_version).to eq(:im6)
      end
    end

    it "caches the detection result" do
      # First call detects and caches
      version1 = described_class.detected_version
      # Second call should return same result without re-detecting
      version2 = described_class.detected_version
      expect(version1).to eq(version2)

      # After reset, it should re-detect
      described_class.reset!
      version3 = described_class.detected_version
      expect(version3).to eq(version1)
    end
  end

  describe ".reset!" do
    it "clears cached detection so it re-runs" do
      im7_cmd = double(run: "Version: ImageMagick 7.1.1-38 Q16-HDRI x86_64")
      allow(Terrapin::CommandLine).to receive(:new)
        .with("magick", "-version", swallow_stderr: true)
        .and_return(im7_cmd)

      described_class.detected_version
      described_class.reset!
      described_class.detected_version

      expect(Terrapin::CommandLine).to have_received(:new)
        .with("magick", "-version", swallow_stderr: true)
        .twice
    end
  end

  describe ".imagemagick7?" do
    context "with auto-detection returning :im7" do
      before do
        allow(described_class).to receive(:detected_version).and_return(:im7)
        Paperclip.options[:imagemagick_version] = nil
      end

      it "returns true" do
        expect(described_class.imagemagick7?).to be true
      end
    end

    context "with auto-detection returning :im6" do
      before do
        allow(described_class).to receive(:detected_version).and_return(:im6)
        Paperclip.options[:imagemagick_version] = nil
      end

      it "returns false" do
        expect(described_class.imagemagick7?).to be false
      end
    end

    context "with auto-detection returning nil" do
      before do
        allow(described_class).to receive(:detected_version).and_return(nil)
        Paperclip.options[:imagemagick_version] = nil
      end

      it "returns false" do
        expect(described_class.imagemagick7?).to be false
      end
    end

    context "with user override :im7" do
      before do
        Paperclip.options[:imagemagick_version] = :im7
        allow(described_class).to receive(:detected_version).and_return(:im6)
      end

      it "returns true regardless of detection" do
        expect(described_class.imagemagick7?).to be true
      end

      it "does not call detected_version" do
        described_class.imagemagick7?
        expect(described_class).not_to have_received(:detected_version)
      end
    end

    context "with user override :im6" do
      before do
        Paperclip.options[:imagemagick_version] = :im6
        allow(described_class).to receive(:detected_version).and_return(:im7)
      end

      it "returns false regardless of detection" do
        expect(described_class.imagemagick7?).to be false
      end

      it "does not call detected_version" do
        described_class.imagemagick7?
        expect(described_class).not_to have_received(:detected_version)
      end
    end
  end

  describe ".convert_command" do
    context "when ImageMagick 7" do
      before { allow(described_class).to receive(:imagemagick7?).and_return(true) }

      it "returns 'magick'" do
        expect(described_class.convert_command).to eq("magick")
      end
    end

    context "when ImageMagick 6" do
      before { allow(described_class).to receive(:imagemagick7?).and_return(false) }

      it "returns 'convert'" do
        expect(described_class.convert_command).to eq("convert")
      end
    end
  end

  describe ".identify_command" do
    context "when ImageMagick 7" do
      before { allow(described_class).to receive(:imagemagick7?).and_return(true) }

      it "returns 'magick identify'" do
        expect(described_class.identify_command).to eq("magick identify")
      end
    end

    context "when ImageMagick 6" do
      before { allow(described_class).to receive(:imagemagick7?).and_return(false) }

      it "returns 'identify'" do
        expect(described_class.identify_command).to eq("identify")
      end
    end
  end

  describe "command_path integration" do
    it "respects Paperclip.options[:command_path] during detection" do
      Paperclip.options[:command_path] = "/custom/imagemagick/bin"

      im7_cmd = double(run: "Version: ImageMagick 7.1.1-38 Q16-HDRI x86_64")
      allow(Terrapin::CommandLine).to receive(:new)
        .with("magick", "-version", swallow_stderr: true)
        .and_return(im7_cmd)

      described_class.detected_version

      expect(Terrapin::CommandLine.path).to include("/custom/imagemagick/bin")
    end
  end
end
