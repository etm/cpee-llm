require_relative 'llm_requests'

def generate_model(myllm,user_input) #{{{
  begin
    llm_response = generate_mermaid_model(myllm,user_input)
    # raise exceptions if response is empty for some reason
    if llm_response.empty?
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

def adapt_model(myllm,doc,user_input) #{{{
  input_cpee = doc.to_s()
  input_mermaid = cpee_to_mermaid(doc.to_s())

  begin
    llm_response = adapt_mermaid_model(myllm,user_input,input_mermaid)
    # raise exceptions if response is empty for some reason
    if llm_response.empty?
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
    if llm_response.empty?
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
