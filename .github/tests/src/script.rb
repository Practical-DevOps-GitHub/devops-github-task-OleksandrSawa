require 'net/http'
require 'uri'
require 'json'
class GithubApi
  @@prefix = 'https://api.github.com/repos'

  def initialize(repo_uri, token)
    @repo_uri =  repo_uri
    @token = token
  end
  def get(url)
    uri = URI.parse("#{@@prefix}/#{@repo_uri}#{"/#{url}" if url != ''}")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/vnd.github+json"
    request["Authorization"] = "Bearer #{@token}"
    request["X-Github-Api-Version"] = "2022-11-28"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end

  def branch_protected?(branch_name)
    branches = JSON.parse(get('branches').body).select{|element| element["name"] == branch_name}
    return "Branch with #{branch_name} doesn't exist" if branches.empty?
    branches[0]["protected"]
  end

  def branch_exist?(branch_name)
    !JSON.parse(get('branches').body).select{|element| element["name"] == branch_name}.empty?
  end

  def branches
    JSON.parse(get('branches').body)
  end

  def branch(json_obj, branch_name)
    JSON.parse(get('branches').body).select{|element| element["name"] == branch_name}
  end

  def default_branch
    JSON.parse(get('').body)["default_branch"]
  end

  def file_branch(file_name, branch_name)
    return nil if get("contents/#{file_name}?ref=#{branch_name}").code != '200'
    old_uri = @@prefix
    @@prefix =  'https://raw.githubusercontent.com'
    result = get("#{branch_name}/#{file_name}").body
    @@prefix = old_uri
    result
  end

  def rules_required_pull_request_reviews(branch_name)
    response = get("branches/#{branch_name}/protection")
    return nil  if response.code != '200'
    JSON.parse(response.body)["required_pull_request_reviews"]
  end

  def deploy_keys
    response = get("keys")
    return nil if response.code != '200'
    JSON.parse(response.body)
  end

end


