module Paperclip
  class AbstractAdapter

    def original_filename
      @original_filename
    end

    def content_type
      @content_type
    end

    def size
      @size
    end

    def fingerprint
      @fingerprint ||= Digest::MD5.file(path).to_s
    end

    def nil?
      false
    end

    def read(length = nil, buffer = nil)
      @tempfile.read(length, buffer)
    end

    # We don't use this directly, but aws/sdk does.
    def rewind
      @tempfile.rewind
    end

    def eof?
      @tempfile.eof?
    end

    def path
      @tempfile.path
    end

    private

    def destination
      @destination ||= TempfileFactory.new.generate(original_filename)
    end

    def copy_to_tempfile(src)
      FileUtils.cp(src.path, destination.path)
      destination
    end

    def best_content_type_option(types)
      best = types.reject {|type| type.content_type.match(/\/x-/) }
      if best.size == 0
        types.first.content_type
      else
        best.first.content_type
      end
    end

    def type_from_file_command
      # On BSDs, `file` doesn't give a result code of 1 if the file doesn't exist.
      type = (File.extname(self.path.to_s)).downcase
      type = "octet-stream" if type.empty?
      mime_type = Paperclip.run("file", "-b --mime :file", :file => self.path).split(/[:;\s]+/)[0]
      mime_type = "application/x-#{type}" if mime_type.match(/\(.*?\)/)
      mime_type
    end
  end
end
