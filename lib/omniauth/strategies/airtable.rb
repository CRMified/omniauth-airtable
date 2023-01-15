require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Airtable < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, "airtable"

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.

      option :client_options, {
        :site => 'https://airtable.com',
        :authorize_url => 'https://airtable.com/oauth2/v1/authorize',
        :token_url => 'https://airtable.com/oauth2/v1/token'
      }

      # You may specify that your strategy should use PKCE by setting
      # the pkce option to true: https://tools.ietf.org/html/rfc7636
      option :pkce, true

      def request_phase
        redirect client.auth_code.authorize_url({:redirect_uri => callback_url.split("?").first}.merge(authorize_params))
      end

      def build_access_token
        verifier = request.params["code"]
        client.auth_code.get_token(verifier, {:redirect_uri => callback_url.split("?").first}.merge(token_params.to_hash(:symbolize_keys => true)))
      end

      def who_am_i

        #TODO

        require 'uri'
        require 'net/http'
        require 'openssl'
        
        url = URI("https://api.airtable.com/v0/meta/whoami")
        
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        
        request1 = Net::HTTP::Get.new(url)
         request1["Authorization"] = "Bearer #{access_token.token}"
        
        response = http.request(request1)
        JSON.parse(response.read_body)
      end

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      uid{ raw_info['id'] }

      info do
        {
          :name => raw_info['name'],
          :email => raw_info['email']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= who_am_i
      end
    end
  end
end