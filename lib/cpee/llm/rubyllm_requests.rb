#!/usr/bin/env ruby
require 'ruby_llm'
require 'typhoeus'
require 'json'

# own llm error class
class LLMError < StandardError #{{{
  attr_reader :http_response
  def initialize(message = "Something went wrong", http_response = 500)
    @http_response = http_response
    super(message)
  end
end #}}}

def connect_llm(mykey,myllm) #{{{
  chat = nil
  RubyLLM.configure do |config|
    case myllm
    when /gpt/
      config.openai_api_key = mykey
      config.openai_use_system_role = true
      chat = RubyLLM.chat(model: myllm,provider: :openai,assume_model_exists: true)
    when /gemini/
      config.gemini_api_key = mykey
      chat = RubyLLM.chat(model: myllm)
    when /mistralai/,/gemma/,/qwen/,/Qwen/
      config.openai_api_key = mykey
      config.openai_api_base = "https://morpheus.cit.tum.de/api/v1"
      config.openai_use_system_role = true
      chat = RubyLLM.chat(model: myllm,provider: :openai,assume_model_exists: true)
    else
      raise LLMError.new("Selected LLM model does not exist or is not supported. Please, select another LLM model.", "", 400)
    end
  end
  return chat
end #}}}

def generate_content(myllm,system_prompt,user_prompt,max_tokens,temperature) #{{{
  case myllm
  when /gpt/
    mykey = File.read File.join(__dir__,'chatgpt.key')
  when /gemini/
    mykey = File.read File.join(__dir__,'gemini.key')
  when /mistralai/,/gemma/,/qwen/,/Qwen/
    mykey = File.read File.join(__dir__,'morpheus.key')
  else
    raise LLMError.new("Selected LLM model does not exist or is not supported. Please, select another LLM model.", "", 400)
  end
  mykey.strip!

  chat = connect_llm(mykey,myllm)
  chat.with_instructions system_prompt
  chat.with_temperature(temperature)
  if myllm.include?("gemini")
    chat.with_params(generationConfig:{maxOutputTokens: max_tokens})
  else
    chat.with_params(max_tokens: max_tokens)
  end
  pp "before response"
  response = chat.ask user_prompt
  pp response
  #puts JSON.parse(response.content)
  return response.content
rescue Exception => e
  raise LLMError.new(e.message, e.response.code)
 end #}}}

def generate_json_content(myllm,system_prompt,user_prompt,max_tokens,temperature) #{{{
  case myllm
  when /gpt/
    mykey = File.read File.join(__dir__,'chatgpt.key')
  when /mistralai/,/gemma/,/qwen/,/Qwen/
    mykey = File.read File.join(__dir__,'morpheus.key')
  else
    puts "ELSE branch"
    raise LLMError.new("Selected LLM model does not exist or is not supported. Please, select another LLM model.", "", 400)
  end
  mykey.strip!
  chat = connect_llm(mykey,myllm)

  #set parameters
  chat.with_params(max_tokens: max_tokens,response_format:{type:'json_object'})
  chat.with_instructions system_prompt
  chat.with_temperature(temperature)
  response = chat.ask user_prompt
  #puts JSON.parse(response.content)
  return response.content
rescue Exception => e
  raise LLMError.new(e.message, e.response.code)
 end #}}}

def generate_mermaid_model(llm, user_input) #{{{
  pp "IN RUBYllm"
  max_tokens = 4000
  temperature = 0.1
  system_prompt = File.read(File.join(__dir__,"prompts/generate1.txt"))
  user_prompt = "Consider following process description: #{user_input}. Generate a BPMN model in Mermaid.js format."
  pp "HERE"
  new_mermaid = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature)
  return new_mermaid
end #}}}

def adapt_mermaid_model(llm, user_input, process_model) #{{{
  pp "IN adapt RUBYllm"
  max_tokens = 4000
  temperature = 0
  system_prompt = File.read(File.join(__dir__,"prompts/apply.txt"))
  user_prompt = "Consider following process model: #{process_model}. Update this process model according to provided changes #{user_input}."
  pp "before new adapt"
  new_mermaid = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature)
  pp "after new adapt"
  return new_mermaid
end #}}}

def generate_plain_text(llm, user_input) #{{{
  max_tokens = 4000
  temperature = 0
  system_prompt = File.read(File.join(__dir__,"prompts/describe.txt"))
  user_prompt = "Consider following process process model: #{user_input}. Generate a text describing provided process description."
  process_description = generate_content(llm,system_prompt,user_prompt,max_tokens,temperature)
  return process_description
end #}}}

def generate_generic_content(llm, user_input, system_prompt, json) #{{{
  pp "start generic"
  max_tokens = 10000
  temperature = 0
  pp json
  if json == 'true'
    pp "in generate json"
    process_description = generate_json_content(llm,system_prompt,user_input,max_tokens,temperature)
  else
    pp "generic"
    process_description = generate_content(llm,system_prompt,user_input,max_tokens,temperature)
    pp "end generic"
  end
  return process_description
  pp "end"
end #}}}

