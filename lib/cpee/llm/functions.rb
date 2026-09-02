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
require 'cpee/transformation/transformer'
require 'cpee/transformation/cpee'
require 'cpee/transformation/mermaid'

module CPEE

  module LLM

    module Functions

      include RubyLLM_Requests

      def cpee_to_mermaid(cpee) #{{{
        model = CPEE::Transformation::Source::CPEE.new(cpee)
        trans = CPEE::Transformation::Transformer.new(model)
        traces = trans.build_traces
        tree = trans.build_tree(false)
        trans.generate_model(CPEE::Transformation::Target::Mermaid)
      end #}}}
      def mermaid_to_cpee(mermaid) #{{{
        model = CPEE::Transformation::Source::Mermaid.new(mermaid)

        trans = CPEE::Transformation::Transformer.new(model)
        traces = trans.build_traces

        tree = trans.build_tree(false)
        trans.generate_model(CPEE::Transformation::Target::CPEE)
      end #}}}

      def error_handler #{{{
        begin
          yield
        rescue LLMError => e_llm
          e_llm.message
          raise e_llm
        rescue Exception => e
          e.message
          raise e
        end
      end #}}}

      def generate_model(myllm,user_input,temperature,llms) #{{{
        error_handler do
          system_prompt = build_system_prompt("generate1.txt")
          user_prompt = build_user_prompt("process_description.txt", user_input:)
          llm_response = generate_content(myllm,system_prompt,user_prompt,4000,temperature,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        end
      end #}}}

      def adapt_model(myllm,doc,user_input,llms) #{{{
        input_cpee = doc.to_s()
        input_mermaid = cpee_to_mermaid(doc.to_s())
        error_handler do
          system_prompt = build_system_prompt("apply.txt")
          user_prompt = build_user_prompt("process_model_adapt.txt", user_input:, process_model: input_mermaid)
          llm_response = generate_content(myllm,system_prompt,user_prompt,4000,0,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        end
      end #}}}

      def adapt_doccpee_description(myllm,doc,user_input,llms) #{{{
        input_cpee = doc.to_s()
        error_handler do
          system_prompt = build_system_prompt("adapt_docxml_description.txt")
          user_prompt = build_user_prompt("process_model_adapt.txt", user_input:, process_model: input_cpee)
          llm_response = generate_content(myllm,system_prompt,user_prompt,20000,0,llms)
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
        end
      end #}}}

      def adapt_cpee_model(myllm,doc,user_input,existing_endpoints,endpoints,llms) #{{{
        testset = XML::Smart.string('<testset xmlns="http://cpee.org/ns/properties/2.0"></testset>')
        root = testset.root
        root.add(existing_endpoints.root)
        dslx = root.add("dslx")
        dslx.add(doc.root)

        error_handler do
          system_prompt = build_system_prompt("adapt_xml_endpoints.txt")
          user_prompt = build_user_prompt("process_model_adapt_api.txt", user_input:, process_model: testset, api_specification: endpoints)
          llm_response = generate_content(myllm,system_prompt,user_prompt,15000,0,llms)
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
        end
      end #}}}

      def generate_text(myllm,doc,llms) #{{{
        input_cpee = doc.to_s()
        input_mermaid = cpee_to_mermaid(doc.to_s())
        error_handler do
          system_prompt = build_system_prompt("describe.txt")
          user_prompt = build_user_prompt("process_model_text.txt", user_input: input_mermaid)
          llm_response = generate_content(myllm,system_prompt,user_prompt,4000,0,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        end
      end #}}}

      def generate_generic(myllm,user_input,system_prompt,format,temperature,llms) #{{{
        error_handler do
          llm_response = generate_content(myllm, system_prompt, user_input, 20000, temperature, llms, format == 'true' ? { json: true } : {})
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        end
      end #}}}

      def generate_dataflow(myllm,mermaid_model,api_specification,llms) #{{{
        error_handler do
          system_prompt = build_system_prompt("dataflow.txt")
          user_prompt = build_user_prompt("dataflow.txt", mermaid_model:, api_specification:)
          llm_response = generate_content(myllm, system_prompt, user_prompt, 4000, 0.1, llms)
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
              hash = JSON.parse(llm_response)
            rescue JSON::ParserError => e
              raise LLMError.new("Something went wrong and llm was not able to generate Json data flow: #{llm_response}", 500)
            end
            return llm_response
          end
        end
      end #}}}

      def generate_endpoint_model(myllm,user_input,endpoints,llms) #{{{
        error_handler do
          system_prompt = build_system_prompt("generate_enpoints.txt")
          user_prompt = build_user_prompt("process_description_endpoints.txt", user_input:, endpoints:)
          llm_response = generate_content(myllm,system_prompt,user_prompt,4000,0.1,llms)
          # raise exceptions if response is empty for some reason
          if llm_response.nil? || llm_response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            return llm_response
          end
        end
      end #}}}

      def validate_cpee_model(myllm,cpee_model,llms) #{{{
        error_handler do
          system_prompt = build_system_prompt("validate_xml.txt")
          user_prompt = build_user_prompt("cpee_repair.txt", cpee_model:)
          llm_response = generate_content(myllm,system_prompt,user_prompt,0,0.1,llms)
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
        end
      end #}}}

      def guess_intent(myllm,user_input,plugins,llms) #{{{
        plugs = File.read(plugins)
        error_handler do
          system_prompt = build_system_prompt("intent.txt")
          user_prompt = build_user_prompt("intent.txt", user_input:, plugins: plugs)
          response = generate_content(myllm,system_prompt,user_prompt,4000,0.1,llms,{ json: true })
          if response.nil? || response.empty?
            raise LLMError.new("Something went wrong and your content was not generated!", 500)
          else
            JSON::parse(response)
          end
        end
      end #}}}

    end

  end

end
