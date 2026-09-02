# This file is part of CPEE-LLM.
#
# CPEE-LLM is free software: you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# CPEE-LLM is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with CPEE-LLM (file LICENSE in the main directory). If not, see
# <http://www.gnu.org/licenses/>.

require 'ruby_llm'
require 'typhoeus'
require 'json'

module CPEE

  module LLM

    # custom llm error class  #{{{
    class LLMError < StandardError
      attr_reader :http_response
      def initialize(message = "Something went wrong", http_response = 500)
        @http_response = http_response
        super(message)
      end
    end #}}}

    module RubyLLM_Requests

      def connect_llm(myllm,llms) #{{{
        chat = nil
        RubyLLM.configure do |config|
          config.request_timeout = llms[:request_timeout]
          config.max_retries = llms[:max_retries]

          llms[:connectors].each do |k,v|
            if myllm =~ /#{k}/ && chat.nil?
              chat = eval(v)
            end
          end

          if chat.nil?
            raise LLMError.new("Selected LLM model does not exist or is not supported. Please, select another LLM model.",  400)
          end
        end
        return chat
      end #}}}

      def build_system_prompt(name) #{{{
        sp = File.read(File.join(__dir__,"prompts","system",name))
        sp.gsub!(/(^|\n)[\t ]*%%%([^\n]+)(\n|$)/) do |e|
          b = $1
          m = $2
          a = $3
          if File.exist? File.join(__dir__,"prompts","system",m)
            "#{a}#{File.read(File.join(__dir__,"prompts","system",m))}#{b}"
          else
            "#{a}#{b}"
          end
        end
        sp
      end #}}}

      def build_user_prompt(name,opts) #{{{
        sp = File.read(File.join(__dir__,"prompts","user",name))
        sp.gsub!(/(^|\n)[\t ]*%%%([^\n]+)(\n|$)/) do |e|
          b = $1
          m = $2.to_sym
          a = $3
          if opts[m]
            "#{a}#{opts[m]}#{b}"
          else
            "#{a}#{b}"
          end
        end
        sp
      end #}}}

      def generate_content(myllm, system_prompt, user_prompt, max_tokens, temperature, llms, opts={}) #{{{
        temperature = temperature.nil? ? 0.1 : temperature.to_f
        chat = connect_llm(myllm,llms)
        chat.with_instructions system_prompt
        chat.with_temperature(temperature)
        if max_tokens != 0
          if myllm.include?("gemini")
            opts[:generationConfig] = { maxOutputTokens: max_tokens }
            opts[:generationConfig].merge!(response_mime_type: 'application/json') if opts[:json]
          elsif myllm.include?("gpt")
            opts[:max_completion_tokens] = max_tokens
            opts[:response_format] = { type: "json_object" } if opts[:json]
          else
            opts[:max_tokens] = max_tokens
          end
        end
        opts.delete(:json)
        chat.with_params **opts
        response = chat.ask user_prompt
        return response.content
      rescue Faraday::TimeoutError => e
        raise LLMError.new(e.message, 504)
      rescue Exception => e
        raise LLMError.new(e.message, 500)
      end #}}}

    end

  end

end
