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

require_relative 'rubyllm_requests'
require 'json'

module CPEE

  module LLM

    module Functions

      include RubyLLM_Requests

      def generate_model(myllm,user_input,temperature,llms) #{{{
        begin
          llm_response = generate_mermaid_model(myllm,user_input,temperature,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        rescue LLMError => e_llm
          e_llm.message
          raise e_llm
        rescue Exception => e
          e.message
          raise e
        end
      end #}}}

      def adapt_model(myllm,doc,user_input,llms) #{{{
        input_cpee = doc.to_s()
        input_mermaid = cpee_to_mermaid(doc.to_s())
        begin
          llm_response = adapt_mermaid_model(myllm,user_input,input_mermaid,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        rescue LLMError => e_llm
          raise e_llm
        rescue Exception => e
          raise e
        end
      end #}}}

      def adapt_cpee_model(myllm,doc,user_input,existing_endpoints,endpoints,llms) #{{{
        testset = XML::Smart.string(<<~XML)
          <testset xmlns="http://cpee.org/ns/properties/2.0">
          </testset>
        XML
        root = testset.root
        root.add(existing_endpoints.root)
        dslx = root.add("dslx")
        dslx.add(doc.root)

        #puts testset.to_s

        begin
          llm_response = adapt_xml_model(myllm,user_input,testset,endpoints,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            llm_response = llm_response.strip
            inside = llm_response.scan(/```(\w+)?\s*\n(.*?)\n```/m)
            llm_response = inside.empty? ? llm_response : inside[0][1]
            #check if response is xml:
            begin
              XML::Smart.string(llm_response)
            rescue Nokogiri::XML::SyntaxError => e
              raise LLMError.new("Something went wrong and llm was not able to generate valid xml model: #{llm_response}", 500)
            end
            return llm_response
          end
        rescue LLMError => e_llm
          raise e_llm
        rescue Exception => e
          raise e
        end
      end #}}}

      def generate_text(myllm,doc,llms) #{{{
        input_cpee = doc.to_s()
        input_mermaid = cpee_to_mermaid(doc.to_s())
        begin
          llm_response = generate_plain_text(myllm,input_mermaid,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        rescue LLMError => e_llm
          e_llm.message
          raise e_llm
        rescue Exception => e
          e.message
          raise e
        end
      end #}}}

      def generate_generic(myllm,user_input,system_prompt,format,temperature,llms) #{{{
        begin
          llm_response = generate_generic_content(myllm, user_input, system_prompt, format, temperature, llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        rescue LLMError => e_llm
          e_llm.message
          raise e_llm
        rescue Exception => e
          e.message
          raise e
        end
      end #}}}

      def generate_dataflow(myllm,mermaid_model,api_specification,llms) #{{{
        begin
          llm_response = generate_dataflow_content(myllm, mermaid_model, api_specification, llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            #check if markdown is there:
            llm_response = llm_response.strip
            inside = llm_response.scan(/```(\w+)?\s*\n(.*?)\n```/m)
            # variable = condition?  if true: if false
            llm_response = inside.empty? ? llm_response : inside[0][1]
            #check if response is json:
            begin
              pp "here"
              hash = JSON.parse(llm_response)
            rescue JSON::ParserError => e
              pp "there"
              raise LLMError.new("Something went wrong and llm was not able to generate Json data flow: #{llm_response}", 500)
            end
            return llm_response
          end
        rescue LLMError => e_llm
          e_llm.message
          raise e_llm
        rescue Exception => e
          e.message
          raise e
        end
      end #}}}

      def generate_endpoint_model(myllm,user_input,endpoints,llms) #{{{
        begin
          llm_response = generate_endpoint_mermaid_model(myllm,user_input,endpoints,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        rescue LLMError => e_llm
          e_llm.message
          raise e_llm
        rescue Exception => e
          e.message
          raise e
        end
      end #}}}

      def validate_cpee_model(myllm,cpee_model,llms) #{{{
        begin
          llm_response = validate_xml_model(myllm,cpee_model,llms)
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          elsif llm_response.strip.downcase == "perfect"
            return cpee_model
          else
            llm_response = llm_response.strip
            inside = llm_response.scan(/```(\w+)?\s*\n(.*?)\n```/m)
            llm_response = inside.empty? ? llm_response : inside[0][1]
            #check if response is xml:
            begin
              XML::Smart.string(llm_response)
            rescue Nokogiri::XML::SyntaxError => e
              raise LLMError.new("Something went wrong and llm was not able to generate valid xml model", llm_response)
            end
            return llm_response
          end
        rescue LLMError => e_llm
          e_llm.message
          raise e_llm
        rescue Exception => e
          e.message
          raise e
        end
      end #}}}

    end

  end

end
