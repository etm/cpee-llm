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



=begin
def handle_error_repeat(llm_response, myllm, myhandler, doc, user_input) #{{{
  if llm_response == 429 || llm_response == 500 || llm_response == 503 || llm_response == 504
    if myllm.include? 'gpt'
      myllm = "gpt-4"
    elsif myllm.include? 'gemini'
      myllm = "gemini-2.5-flash-preview-04-17"
    end
  elsif llm_response == 404
    raise LLMError.new("Your request is wrong :(", llm_response)
  else
    if myllm.include? 'gpt'
      myllm = "gemini-2.5-pro-preview-05-06"
    elsif myllm.include? 'gemini'
      myllm = "gpt-4o"
    end
  end
  if(myhandler == :generate_model) then
    llm_reponse = send(myhandler,myllm,user_input)
  elseif(myhandler == :adapt_model)
    llm_reponse = send(myhandler,myllm,doc,user_input)
  else
    raise "incorrect function in repeating"
  end
  return llm_response
end #}}}

# function to generate or adapt mermaid model
def main_function(myllm,doc,user_input) #{{{
  input_cpee = doc.to_s()
  if(doc.root().empty?()) then
    llm_response = generate_mermaid_model(myllm,user_input) || ""
  else
    input_mermaid = cpee_to_mermaid(doc.to_s())
    exit()
    llm_response = adapt_mermaid_model(myllm,user_input,input_mermaid) || ""
  end

  # raise exceptions
  if llm_response.is_a? Integer
    raise LLMError.new("LLM does not work :(", llm_response)
  else
    if llm_response.empty?
      raise LLMError.new("Something went wrong :(", llm_response)
    end
  end
  return llm_response
end #}}}

# function to handle llm errors to execute request one more time if necessary
def llm_error_handling(llm_response, myllm, myhandler, doc, user_input) #{{{
  if llm_response.is_a? Integer
    # we can select another gemini or gpt model and start the process again
    # 503 # The model is overloaded. Please try again later.
    # 500 # An unexpected error occurred on Google's side.
    # 429 # You've exceeded the rate limit.
    # 504 # The service is unable to finish processing within the deadline.
    if llm_response == 429 || llm_response == 500 || llm_response == 503 || llm_response == 504
      if myllm.include? 'gpt'
        myllm = "gpt-4"
      elsif myllm.include? 'gemini'
        myllm = "gemini-2.5-flash-preview-04-17"
      end
      final_response = myhandler.call(myllm, doc, user_input)
    else
      if myllm.include? 'gpt'
        myllm = "gemini-2.5-pro-preview-05-06"
      elsif myllm.include? 'gemini'
        myllm = "gpt-4o"
      end
      final_response = myhandler.call(myllm, doc, user_input)
    end
  elsif
    if llm_response.empty?
      # "smth went wrong and model was not generated. try one more time as it was"
      final_response = myhandler.call(myllm, doc, user_input)
    else
      # "everything is good, do nothing"
      final_response = llm_response
    end
  end
  return final_response
end #}}}
=end
