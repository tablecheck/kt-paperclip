require "spec_helper"

describe Paperclip::Processor do
  it "instantiates and call #make when sent #make to the class" do
    processor = double
    expect(processor).to receive(:make)
    expect(Paperclip::Processor).to receive(:new).with(:one, :two, :three).and_return(processor)
    Paperclip::Processor.make(:one, :two, :three)
  end

  context "Calling #convert" do
    before { Paperclip.options[:log_command] = false }
    after { Paperclip.options[:log_command] = true }

    context "with ImageMagick 6" do
      before do
        allow(Paperclip::ImageMagickVersionDetector).to receive(:convert_command).and_return("convert")
      end

      it "runs the convert command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("convert", "stuff", {}).and_return(double(run: nil))
        Paperclip::Processor.new("filename").convert("stuff")
      end
    end

    context "with ImageMagick 7" do
      before do
        allow(Paperclip::ImageMagickVersionDetector).to receive(:convert_command).and_return("magick")
      end

      it "runs the magick command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("magick", "stuff", {}).and_return(double(run: nil))
        Paperclip::Processor.new("filename").convert("stuff")
      end
    end
  end

  context "Calling #identify" do
    before { Paperclip.options[:log_command] = false }
    after { Paperclip.options[:log_command] = true }

    context "with ImageMagick 6" do
      before do
        allow(Paperclip::ImageMagickVersionDetector).to receive(:identify_command).and_return("identify")
      end

      it "runs the identify command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("identify", "stuff", {}).and_return(double(run: nil))
        Paperclip::Processor.new("filename").identify("stuff")
      end
    end

    context "with ImageMagick 7" do
      before do
        allow(Paperclip::ImageMagickVersionDetector).to receive(:identify_command).and_return("magick identify")
      end

      it "runs the magick identify command with Terrapin" do
        expect(Terrapin::CommandLine).to receive(:new).with("magick identify", "stuff", {}).and_return(double(run: nil))
        Paperclip::Processor.new("filename").identify("stuff")
      end
    end
  end
end
