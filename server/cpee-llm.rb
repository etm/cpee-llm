#!/usr/bin/ruby
require 'riddl/server'
require 'riddl/client'
require 'xml/smart'
require 'json'
require 'typhoeus'
require_relative '../lib/cpee/llm/llm_functions'

def cpee_to_mermaid(cpee) #{{{
  srv = Riddl::Client.new('http://localhost:9295/mermaid/cpee')
  status, res = srv.post [
    Riddl::Parameter::Complex.new("description","text/xml",cpee),
    Riddl::Parameter::Simple.new("type","description")
  ]
  if status >= 200 && status < 300
    res
  else
    raise 'error when converting cpee to mermaid'
  end
  return res[0].value().read()
end #}}}

def mermaid_to_cpee(mermaid) #{{{
  #srv = Riddl::Client.new('http://localhost:9295/mermaid')
  srv = Riddl::Client.new('http://localhost:9295/cpee/mermaid')
  status, res = srv.post [
    Riddl::Parameter::Complex.new("description","text/plain",mermaid),
    Riddl::Parameter::Simple.new("type","description")
  ]
  if status >= 200 && status < 300
    res
  else
    puts mermaid
    raise 'error when converting mermaid to cpee'
  end
  pp res
  pp res[0].value().read()
  res[0].value().rewind()
  return res[0].value().read()
end #}}}

class CreateMermaid < Riddl::Implementation #{{{
  def response
    #get parameters
    begin
      input_cpee = @p[0].value().read()
      user_input = @p[1].value().read()
      myllm = @p[2].value().read()
      doc = XML::Smart.string(input_cpee)
      pp "incoming cpee: #{doc.to_s()}"
      File.write('incoming_cpee.xml',doc.to_s())
      pp "incoming user_input: #{user_input}"
      pp "used model: #{myllm}"
    rescue Exception => e
      @status = 400
      return Riddl::Parameter::Complex.new("llm_out","application/json",{:error => e}.to_json())
    end

    if(doc.root().empty?()) then
      begin
        llm_response = generate_model(myllm,user_input)
      rescue LLMError => e
        pp "LLMError #{e.http_response}"
        @status = e.http_response
        return Riddl::Parameter::Complex.new("llm_out","application/json",{:error => e.message}.to_json())
      end
    else
      begin
        llm_response = adapt_model(myllm,doc,user_input)
      rescue LLMError => e
        pp "LLMError #{e.http_response}"
        @status = e.http_response
        return Riddl::Parameter::Complex.new("llm_out","application/json",{:error => e.message}.to_json())
      end
    end

=begin
    # make a call to llm
    #myllm = "gemini-2.0-flash"
    begin
      final_response = main_function(myllm, doc, user_input)
    rescue LLMError => e
      puts e.message
      final_response = llm_error_handling(e.llm_response, myllm, method(:main_function), doc, user_input)
    end
=end

    # convert llm response to cpee tree
    # only for testing
    # final_response = File.read(File.join(__dir__,'mermaid_example'))
    # only for testing
    begin
      pp "outgoing mermaid: #{llm_response}"
      File.write('outgoing_mermaid.mmd',llm_response)
      output_cpee = mermaid_to_cpee(llm_response)
      pp "outgoing cpee: #{output_cpee}"
      File.write('outgoing_cpee.xml',output_cpee)
    rescue Exception => e
      @status = 500
      return Riddl::Parameter::Complex.new("llm_out","application/json",{:error => e}.to_json())
    end

    return(Riddl::Parameter::Complex.new("llm_out","application/json",{:user_input => user_input, :used_llm => myllm, :input_cpee => input_cpee, :input_intermediate => doc.root().empty?() ? "" : cpee_to_mermaid(doc.to_s()), :output_intermediate => llm_response, :output_cpee => output_cpee, :status => "success"}.to_json()))
    #return Riddl::Parameter::Complex.new("llm_out","application/json",{:input_cpee => input_cpee, :input_intermediate => "", :output_intermediate => llm_response, :output_cpee => output_cpee, :status => ""}.to_json())
  end
end #}}}

class CreateText < Riddl::Implementation #{{{
  def response
    type = @a[0]
    begin
      input_cpee = @p[0].value.read
      myllm = @p[1].value
      doc = XML::Smart.string(input_cpee)
      pp "incoming cpee: #{doc.to_s}"
      File.write('incoming_cpee.xml',doc.to_s)
      pp "used model: #{myllm}"
    rescue Exception => e
      @status = 400
      return Riddl::Parameter::Complex.new('llm_out','application/json',{:error => e}.to_json())
    end

    if doc.root.empty?
      @status = 400
      return Riddl::Parameter::Complex.new('text_out','application/json',{:error => e}.to_json())
    else
      begin
        llm_response = generate_text(myllm,doc)
      rescue LLMError => e
        pp "LLMError #{e.http_response}"
        @status = e.http_response
        return Riddl::Parameter::Complex.new('text_out','application/json',{:error => e.message}.to_json())
      end
    end
    begin
      pp "outgoing text: #{llm_response}"
      File.write('outgoing_text.txt',llm_response)
      output_cpee = mermaid_to_cpee(llm_response)
    rescue Exception => e
      @status = 500
      return Riddl::Parameter::Complex.new('text_out','application/json',{:error => e}.to_json())
    end

    return(Riddl::Parameter::Complex.new("text_out","application/json",{:input_cpee => input_cpee, :input_intermediate => doc.root.empty? ? '' : cpee_to_mermaid(doc.to_s), :output_text => llm_response, :status => 'success'}.to_json()))
  end
end #}}}

Riddl::Server.new(File.dirname(__FILE__) + '/cpee-llm.xml', :port => 9297) do
  accessible_description true
  cross_site_xhr true

  on resource do
    run CreateMermaid if post 'llm_in'
    on resource 'text' do
      on resource 'llm' do
        run(CreateText, 'llm') if post 'text_in'
      end
    end
  end
end.loop!

