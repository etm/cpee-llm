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

require 'riddl/server'
require 'riddl/client'
require 'xml/smart'
require 'json'
require_relative 'functions'
require_relative 'dataflow'

module CPEE

  module LLM

    SERVER = File.expand_path(File.join(__dir__,'implementation.xml'))

    class CreateMermaid < Riddl::Implementation #{{{
      include Functions
      include DataFlow

      def response
        llms = @a[0]
        input_cpee  = @p.shift.value.read
        user_input  = @p.shift.value.read
        myllm       = @p.shift.value.read
        prompt_type = @p.shift.value.read if @p[0]&.name == 'prompt_type'
        endpoints   = @p.shift.value.read if @p[0]&.name == 'endpoints'
        temperature = @p.shift.value.read if @p[0]&.name == 'temperature'

        doc = XML::Smart.string(input_cpee)
        begin
          output_cpee = if prompt_type == 'generate_noendpoints'
            llm_response = generate_model(myllm,user_input,temperature,llms)
            mermaid_to_cpee(llm_response)
          elsif prompt_type == 'generate_endpoints'
            # get endpoints (hardcoded for demo, in future separate step)
            llm_response = generate_endpoint_model(myllm,user_input,get_demo_endpoints(),llms)
            mermaid_to_cpee(llm_response)
          elsif prompt_type == 'adapt_noendpoints'
            llm_response = adapt_model(myllm,doc,user_input,llms)
            mermaid_to_cpee(llm_response)
          elsif prompt_type == 'adapt_endpoints'
            xml_endpoints = XML::Smart.string(endpoints)
            adapt_cpee_model(myllm,doc,user_input,xml_endpoints,get_demo_endpoints(),llms)
          end
        rescue Exception => e
          @status = 500
          return Riddl::Parameter::Complex.new('llm_out', 'application/json', { error: e }.to_json)
        end

        return(Riddl::Parameter::Complex.new("llm_out","application/json",{:user_input => user_input, :used_llm => myllm, :input_cpee => input_cpee, :input_intermediate => doc.root().empty?() ? "" : cpee_to_mermaid(doc.to_s()), :output_intermediate => llm_response, :output_cpee => output_cpee, :status => "Success"}.to_json()))
      rescue LLMError => e
        @status = e&.http_response || 400
        return Riddl::Parameter::Complex.new("llm_out","application/json",{ :error => "#{prompt_type} #{e.message}"}.to_json())
      end
    end #}}}

    class CreateText < Riddl::Implementation #{{{
      include Functions

      def response
        llms = @a[0]
        input_cpee  = @p.shift.value.read
        begin
          input_cpee = @p[0].value.read
          myllm = @p[1].value
          doc = XML::Smart.string(input_cpee)
        rescue Exception => e
          @status = 400
          return Riddl::Parameter::Complex.new('llm_out','application/json',{:error => e}.to_json())
        end

        if doc.root.empty?
          @status = 400
          return Riddl::Parameter::Complex.new('text_out','application/json',{:error => e}.to_json())
        else
          begin
            llm_response = generate_text(myllm,doc,llms)
          rescue LLMError => e
            @status = e.http_response
            return Riddl::Parameter::Complex.new('text_out','application/json',{:error => e.message}.to_json())
          end
        end
        begin
          output_cpee = mermaid_to_cpee(llm_response)
        rescue Exception => e
          @status = 500
          return Riddl::Parameter::Complex.new('text_out','application/json',{:error => e}.to_json())
        end

        return(Riddl::Parameter::Complex.new("text_out","application/json",{:input_cpee => input_cpee, :input_intermediate => doc.root.empty? ? '' : cpee_to_mermaid(doc.to_s), :output_text => llm_response, :status => 'Success'}.to_json()))
      end
    end #}}}

    class CreateGeneric < Riddl::Implementation #{{{
      include Functions

      def response
        llms = @a[0]
        #get parameters
        begin
          myllm = @p[0].value.read
          user_input = @p[1].value.read
          system_prompt = @p[2].value.read
          format = @p[3].value.read
          temperature = @p[4]&.value&.read
        rescue Exception => e
          @status = 400
          return Riddl::Parameter::Complex.new("generic_out","application/json",{:error => e}.to_json())
        end

        begin
          llm_response = generate_generic(myllm,user_input,system_prompt,format,temperature,llms)
        rescue LLMError => e
          @status = e.http_response
          return Riddl::Parameter::Complex.new("generic_out","application/json",{:error => e.message}.to_json())
        end

        return(Riddl::Parameter::Complex.new("generic_out","application/json",{:user_input => user_input, :used_llm => myllm, :system_prompt => system_prompt, :llm_response => llm_response, :status => "Success"}.to_json()))
      end
    end #}}}

    class CreateDataFlow < Riddl::Implementation #{{{
      include Functions
      include DataFlow

      def response
        llms = @a[0]

        #get parameters
        begin
          input_cpee = @p[0].value().read()
          myllm = @p[1].value().read()
          doc = XML::Smart.string(input_cpee)
        rescue Exception => e
          @status = 400
          return Riddl::Parameter::Complex.new("llm_out","application/json",{:error => e}.to_json())
        end
        begin
          mermaid_model = cpee_to_mermaid(doc.to_s())
          #get endpoints (hardcoded for demo, in future separate step)
          endpoints_description = get_demo_endpoints()
          #match tasks and endpoints
          api_speck = get_matching_endpoints(doc,endpoints_description)
        rescue Exception => e
          @status = 500
          return Riddl::Parameter::Complex.new('llm_out', 'application/json', { error: e }.to_json)
        end

        #generate data flow
        begin
          dataflow = generate_dataflow(myllm,mermaid_model,api_speck,llms)
        rescue LLMError => e
          @status = e.http_response || 400
          return Riddl::Parameter::Complex.new("llm_out","application/json",{:error => e.message}.to_json())
        end

        #integrate dataflow in cpee_model
        final_cpee, endpoints = integrate_dataflow(doc,dataflow)

        return(Riddl::Parameter::Complex.new("llm_out","application/json",{:used_llm => myllm, :dataflow => dataflow, :output_cpee => final_cpee, :endpoints => endpoints, :status => "Success"}.to_json()))
      end
    end #}}}

    class ValidateDataFlow < Riddl::Implementation #{{{
      include Functions

      def response
        llms = @a[0]

        #get parameters
        begin
          input_cpee = @p[0].value().read()
          myllm = @p[1].value().read()
          doc = XML::Smart.string(input_cpee)
        rescue Exception => e
          @status = 400
          return Riddl::Parameter::Complex.new("llm_out","application/json",{:error => e}.to_json())
        end

        begin
          llm_response = validate_cpee_model(myllm,input_cpee,llms)
        rescue LLMError => e
          @status = e.http_response
          return Riddl::Parameter::Complex.new("generic_out","application/json",{:error => e.message}.to_json())
        end

        return(Riddl::Parameter::Complex.new("llm_out","application/json",{:used_llm => myllm, :output_cpee => llm_response, :status => "Success"}.to_json()))
      end
    end #}}}

    def self::implementation(opts)
      Proc.new do
        on resource do
          run(CreateMermaid, opts[:llms]) if post 'llm_in'

          on resource 'dataflow' do
            run(CreateDataFlow, opts[:llms]) if post 'dataflow_in'
          end

          on resource 'validate' do
            on resource 'xml' do
              run(ValidateDataFlow, opts[:llms]) if post 'dataflow_in'
            end
          end

          on resource 'text' do
            on resource 'llm' do
              run(CreateText, opts[:llms]) if post 'text_in'
            end
          end

          on resource 'generic' do
            run(CreateGeneric, opts[:llms]) if post 'generic_in'
          end
        end
      end
    end

  end
end
