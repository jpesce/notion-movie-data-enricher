require "net/http"
require "json"

# Extend Net module to add to_json to requests and repsonses

module ParseBody
  private

  def parse_body(body)
    return nil if body.nil? || body.empty?

    begin
      JSON.parse(body) # Attempt to parse as JSON
    rescue JSON::ParserError
      body # Return as string if not JSON
    end
  end
end

module Net
  class HTTPRequest
    include ParseBody

    def to_json
      {
        method: self.method,
        url: self.uri.to_s,
        headers: self.each_header.to_h,
        body: parse_body(self.body)
      }.to_json
    end
  end

  class HTTPResponse
    include ParseBody

    def to_json
      {
        status_code: self.code.to_i,
        headers: self.each_header.to_h,
        body: parse_body(self.body)
      }.to_json
    end
  end
end
