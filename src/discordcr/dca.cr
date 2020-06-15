require "json"

module Discord
  # Parser for the DCA file format, a simple wrapper around Opus made
  # specifically for Discord bots.
  class DCAParser
    # Magic string that identifies a DCA1 file
    DCA1_MAGIC = "DCA1"

    # The parsed metadata, or nil if it could not be parsed.
    getter metadata : DCA1Mappings::Metadata?

    # Create a new parser. It will read from the given *io*. If *raw* is set,
    # the file is assumed to be a DCA0 file, without any metadata. If the file's
    # metadata doesn't conform to the DCA1 specification and *strict_metadata*
    # is set, then the parsing will fail with an error; if it is not set then
    # the metadata will silently be `nil`.
    def initialize(@io : IO, raw = false, @strict_metadata = true)
      unless raw
        verify_magic
        parse_metadata
      end
    end

    # Reads the next frame from the IO. If there is nothing left to read, it
    # will return `nil`.
    #
    # If *reuse_buffer* is true, a large buffer will be allocated once and
    # reused for future calls of this method, reducing the load on the GC and
    # potentially reusing memory use overall; if it is false, a new buffer of
    # just the correct size will be allocated every time. Note that if the
    # buffer is reused, the returned data is only valid until the next call to
    # `next_frame`.
    def next_frame(reuse_buffer = false) : Bytes?
      begin
        header = @io.read_bytes(Int16, IO::ByteFormat::LittleEndian)
        raise "Negative frame header (#{header} < 0)" if header < 0

        buf = if reuse_buffer
                full_buf = @reused_buffer ||= Bytes.new(Int16::MAX)
                full_buf[0, header]
              else
                Bytes.new(header)
              end

        @io.read_fully(buf)
        buf
      rescue IO::EOFError
        nil
      end
    end

    # Continually reads frames from the IO until there are none left. Each frame
    # is passed to the given *block*.
    def parse(&block : Bytes ->)
      loop do
        buf = next_frame

        if buf
          block.call(buf)
        else
          break
        end
      end
    end

    private def verify_magic
      magic = @io.read_string(4)
      if magic != DCA1_MAGIC
        raise "File is not a DCA1 file (magic is #{magic}, should be DCA1)"
      end
    end

    private def parse_metadata
      # The header of the metadata part is the four-byte size of the following
      # metadata payload.
      metadata_size = @io.read_bytes(Int32, IO::ByteFormat::LittleEndian)
      metadata_io = IO::Sized.new(@io, read_size: metadata_size)

      begin
        @metadata = DCA1Mappings::Metadata.from_json(metadata_io)
      rescue e : JSON::ParseException
        raise e if @strict_metadata
      end

      metadata_io.skip_to_end
    end
  end

  # Mappings for DCA1 metadata
  module DCA1Mappings
    struct Metadata
      include JSON::Serializable

      property dca : DCA
      property opus : Opus
      property info : Info?
      property origin : Origin?
      property extra : JSON::Any
    end

    struct DCA
      include JSON::Serializable

      property version : Int32
      property tool : Tool
    end

    struct Tool
      include JSON::Serializable

      property name : String
      property version : String
      property url : String?
      property author : String?
    end

    struct Opus
      include JSON::Serializable

      property mode : String
      property sample_rate : Int32
      property frame_size : Int32
      property abr : Int32?
      property vbr : Bool
      property channels : Int32
    end

    struct Info
      include JSON::Serializable

      property title : String?
      property artist : String?
      property album : String?
      property genre : String?
      property comments : String?
      property cover : String?
    end

    struct Origin
      include JSON::Serializable

      property source : String?
      property abr : Int32?
      property channels : Int32?
      property encoding : String?
      property url : String?
    end
  end
end
