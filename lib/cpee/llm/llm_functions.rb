require_relative 'rubyllm_requests'
require 'json'

def generate_model(myllm,user_input) #{{{
  begin
    llm_response = generate_mermaid_model(myllm,user_input)
    # raise exceptions if response is empty for some reason
    if llm_response.nil? || llm_response.empty?
      raise LLMError.new("Something went wrong and your content was not generated", llm_response)
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

def adapt_model(myllm,doc, user_input) #{{{
  input_cpee = doc.to_s()
  File.write("debug_input_cpee.xml",doc.to_s())
  input_mermaid = cpee_to_mermaid(doc.to_s())

  begin
    llm_response = adapt_mermaid_model(myllm,user_input,input_mermaid)
    # raise exceptions if response is empty for some reason
    if llm_response.nil? || llm_response.empty?
      raise LLMError.new("Something went wrong and your content was not generated", llm_response)
    else
      return llm_response
    end
  rescue LLMError => e_llm
    raise e_llm
  rescue Exception => e
    raise e
  end
end #}}}

def generate_text(myllm,doc) #{{{
  input_cpee = doc.to_s()
  input_mermaid = cpee_to_mermaid(doc.to_s())
  begin
    llm_response = generate_plain_text(myllm,input_mermaid)
    # raise exceptions if response is empty for some reason
    if llm_response.nil? || llm_response.empty?
      raise LLMError.new("Something went wrong and your content was not generated", llm_response)
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

def generate_generic(myllm ,user_input,system_prompt,format) #{{{
  begin
    llm_response = generate_generic_content(myllm, user_input, system_prompt, format)
    # raise exceptions if response is empty for some reason
    if llm_response.nil? || llm_response.empty?
      raise LLMError.new("Something went wrong and your content was not generated", llm_response)
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

def generate_dataflow(myllm,mermaid_model,api_specification) #{{{
  begin
    llm_response = generate_dataflow_content(myllm, mermaid_model, api_specification)
    # raise exceptions if response is empty for some reason
    if llm_response.nil? || llm_response.empty?
      raise LLMError.new("Something went wrong and your content was not generated", llm_response)
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
        raise LLMError.new("Something went wrong and llm was not able to generate Json data flow", llm_response)
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

def generate_endpoint_model(myllm,user_input,endpoints) #{{{
  begin
    llm_response = generate_endpoint_mermaid_model(myllm,user_input,endpoints)
    # raise exceptions if response is empty for some reason
    if llm_response.nil? || llm_response.empty?
      raise LLMError.new("Something went wrong and your content was not generated", llm_response)
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

def validate_cpee_model(myllm,cpee_model) #{{{
  begin
    llm_response = validate_xml_model(myllm,cpee_model)
    # raise exceptions if response is empty for some reason
    if llm_response.nil? || llm_response.empty?
      raise LLMError.new("Something went wrong and your content was not generated", llm_response)
    elsif llm_response.strip.downcase == "perfect"
      return cpee_model
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

