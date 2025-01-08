require 'net/http'
require 'uri'


def check_is_project_public(project_link)
    uri = URI.parse(project_link)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    return response.is_a?(Net::HTTPOK) 
end
