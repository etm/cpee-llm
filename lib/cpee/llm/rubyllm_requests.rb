require 'ruby_llm'
require 'typhoeus'
require 'json'

module CPEE

  module LLM

    # own llm error class
    class LLMError < StandardError #{{{
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

      def generate_content(myllm, system_prompt, user_prompt, max_tokens, temperature, llms) #{{{
        chat = connect_llm(myllm,llms)
        chat.with_instructions system_prompt
        chat.with_temperature(temperature)
        if max_tokens != 0
          if myllm.include?("gemini")
            chat.with_params(generationConfig:{maxOutputTokens: max_tokens})
          elsif myllm.include?("gpt")
            chat.with_params(max_completion_tokens: max_tokens)
          else
            chat.with_params(max_tokens: max_tokens)
          end
        end
        response = chat.ask user_prompt
        return response.content
      rescue Faraday::TimeoutError => e
        raise LLMError.new(e.message, 504)
      rescue Exception => e
        raise LLMError.new(e.message, 500)
       end #}}}

      def generate_json_content(myllm,system_prompt,user_prompt,max_tokens,temperature,llms) #{{{
        chat = connect_llm(myllm,llms)

        #set parameters
        chat.with_params(max_tokens: max_tokens,response_format:{type:'json_object'})
        chat.with_instructions system_prompt
        chat.with_temperature(temperature)
        response = chat.ask user_prompt
        #puts JSON.parse(response.content)
        return response.content
      rescue Faraday::TimeoutError => e
        raise LLMError.new(e.message, 504)
      rescue Exception => e
        raise LLMError.new(e.message, 500)
       end #}}}

      def generate_mermaid_model(llm, user_input, temperature, llms={}) #{{{
        max_tokens = 4000
        temperature = temperature.nil? ? 0.1 : temperature.to_f
        pp "here"
        pp temperature
        system_prompt = File.read(File.join(__dir__,"prompts/generate1.txt"))
        user_prompt = "Consider following process description: #{user_input}. Generate a BPMN model in Mermaid.js format."
        new_mermaid = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature,llms)
        return new_mermaid
      end #}}}

      def adapt_mermaid_model(llm, user_input, process_model, llms={}) #{{{
        max_tokens = 4000
        temperature = 0
        system_prompt = File.read(File.join(__dir__,"prompts/apply.txt"))
        user_prompt = "Consider following process model: #{process_model}. Update this process model according to provided changes #{user_input}."
        new_mermaid = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature,llms)
        return new_mermaid
      end #}}}

      def adapt_xml_model(llm, user_input, process_model, api_specification, llms={}) #{{{
        max_tokens = 20000
        temperature = 0
        system_prompt = File.read(File.join(__dir__,"prompts/adapt_xml.txt"))
        user_prompt = "Consider following process model: #{process_model.to_s} and task specification #{api_specification} with endpoint data. Update this process model according to provided changes #{user_input}."
        new_cpee = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature,llms)
        return new_cpee
      end #}}}

      def generate_plain_text(llm, user_input, llms={}) #{{{
        max_tokens = 4000
        temperature = 0
        system_prompt = File.read(File.join(__dir__,"prompts/describe.txt"))
        user_prompt = "Consider following process process model: #{user_input}. Generate a text describing provided process description."
        process_description = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature,llms)
        return process_description
      end #}}}

      def generate_generic_content(llm, user_input, system_prompt, json, temperature, llms={}) #{{{
        max_tokens = 20000
        temperature = temperature.nil? ? 0 : temperature.to_f
        if json == 'true'
          process_description = generate_json_content(llm,system_prompt,user_input,max_tokens,temperature,llms)
        else
          process_description = generate_content(llm,system_prompt,user_input,max_tokens,temperature,llms)
        end
        return process_description
      end #}}}

      def generate_dataflow_content(llm, mermaid_model, api_specification, llms={}) #{{{
        max_tokens = 10000
        temperature = 0.1
        system_prompt = File.read(File.join(__dir__,"prompts/dataflow.txt"))
        user_prompt = "Given process mode #{mermaid_model} and task specification #{api_specification} with endpoint data, define the execution context and return a JSON specification."
        dataflow = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature,llms)
        return dataflow
      end #}}}

      def generate_endpoint_mermaid_model(llm, user_input, endpoints, llms={}) #{{{
        max_tokens = 4000
        temperature = 0.1
        system_prompt = File.read(File.join(__dir__,"prompts/generate_enpoints.txt"))
        user_prompt = "Consider the following process description: #{user_input} and the provided endpoint list: #{endpoints}. Interpret the process description as business intent and generate an executable BPMN model in Mermaid.js format using only the available endpoint capabilities."
        new_mermaid = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature,llms)
        return new_mermaid
      end #}}}

      def validate_xml_model(llm, cpee_model, llms={}) #{{{
        max_tokens = 0
        temperature = 0.1
        system_prompt = File.read(File.join(__dir__,"prompts/validate_xml.txt"))
        user_prompt = "Consider following CPEE XML promcess model created by autobpmn.ai: #{cpee_model}. Repair the model so that it becomes executable. Return only the repaired XML without any comments or markdown formatting."
        repaired_cpee = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature,llms)
        return repaired_cpee
      end #}}}

    end

  end

end
