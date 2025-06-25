#!/usr/bin/env ruby
require 'llm'
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

def connect_gpt(mykey,myllm) #{{{
  llm = LLM.openai(key: mykey)
  model = llm.models.all.find { |m| m.id == myllm }
  if model.nil?
    raise LLMError.new("Selected LLM model does not exist or is not supported. Please, select another LLM model.", "", 400)
  else
    bot = LLM::Chat.new(llm, model:)
  end
end #}}}

def check_gemini_model(mykey,myllm) #{{{
  request = Typhoeus::Request.new(
    "https://generativelanguage.googleapis.com/v1beta/models/#{myllm}?key=#{mykey}",
    method: :get
  )
  request.run
  response = request.response
  if response.code == 200
    return true
  else
    raise LLMError.new(JSON.parse(response.body)["error"]["message"], response.code)
  end
end #}}}

def connect_gemini(mykey,myllm) #{{{
  check_gemini_model(mykey,myllm)
  request = Typhoeus::Request.new(
    "https://generativelanguage.googleapis.com/v1beta/models/#{myllm}:generateContent?key=#{mykey}",
    method: :post,
    headers: {'Content-Type'=> "application/json"}
  )
  return request
end #}}}

def generate_gpt(myllm,system_prompt,user_prompt,max_tokens,temperature) #{{{
  mykey = File.read File.join(__dir__,'chatgpt.key')
  mykey.strip!
  bot = connect_gpt(mykey,myllm)
  #system prompt
  bot.chat system_prompt, role: :system, temperature: temperature, max_tokens: max_tokens
  #user prompt
  bot.chat user_prompt, role: :user, temperature: temperature, max_tokens: max_tokens
  response = []
  bot.messages.select(&:assistant?).each{response.append(_1.content)}
  return response[1]
rescue Exception => e
  raise LLMError.new(e.message, e.response.code)
end #}}}

def generate_gemini(myllm,system_prompt,user_prompt,max_tokens,temperature) #{{{
  file = File.open File.join(__dir__,"prompts/gemini-request.json")

  request_body = JSON.load file
  request_body["system_instruction"]["parts"][0]["text"] = system_prompt
  request_body["contents"][0]["parts"][0]["text"] = user_prompt
  request_body["generationConfig"]["temperature"] = temperature
  request_body["generationConfig"]["maxOutputTokens"] = max_tokens
  mykey = File.read File.join(__dir__,'gemini.key')
  mykey.strip!
  request = connect_gemini(mykey,myllm)
  request.options[:body] = request_body.to_json
  request.run
  response = request.response
  response_code = response.code
  if response_code != 200
    raise LLMError.new("Gemini failed. Smth went wrong and your content was not generated!", response_code)
  else
    response_body = JSON.parse(response.body)
    final = response_body["candidates"][0]["content"]["parts"][0]["text"]
  end
  return final
end #}}}

def generate_mermaid_model(llm, user_input) #{{{
  max_tokens = 4000
  temperature = 0
  system_prompt = File.read(File.join(__dir__,"prompts/generate.txt"))
  user_prompt = "Consider following process description: #{user_input}. Generate a BPMN model in Mermaid.js format."
  if llm.include? 'gpt'
    new_mermaid = generate_gpt(llm,system_prompt,user_prompt,max_tokens,temperature)
  elsif llm.include? 'gemini'
    new_mermaid = generate_gemini(llm,system_prompt,user_prompt,max_tokens,temperature)
  end
  return new_mermaid
end #}}}

def adapt_mermaid_model(llm, user_input, process_model) #{{{
  max_tokens = 4000
  temperature = 0
  system_prompt = File.read(File.join(__dir__,"prompts/apply.txt"))
  user_prompt = "Consider following process model: #{process_model}. Update this process model according to provided changes #{user_input}."
  if llm.include? 'gpt'
    new_mermaid = generate_gpt(llm,system_prompt,user_prompt,max_tokens,temperature)
  elsif llm.include? 'gemini'
    new_mermaid = generate_gemini(llm,system_prompt,user_prompt,max_tokens,temperature)
  end
  return new_mermaid
end #}}}

def generate_plain_text(llm, user_input) #{{{
  max_tokens = 4000
  temperature = 0
  system_prompt = File.read(File.join(__dir__,"prompts/describe.txt"))
  user_prompt = "Consider following process process model: #{user_input}. Generate a text describing provided process description."
  if llm.include? 'gpt'
    process_description = generate_gpt(llm,system_prompt,user_prompt,max_tokens,temperature)
  elsif llm.include? 'gemini'
    process_description = generate_gemini(llm,system_prompt,user_prompt,max_tokens,temperature)
  end
  return process_description
end #}}}

