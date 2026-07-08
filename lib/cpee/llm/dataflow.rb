#!/usr/bin/env ruby
require 'typhoeus'
require 'xml/smart'
require 'cgi'
require 'rag_embeddings'

# disable Logging, rag_emb uses langchain
Langchain.logger.level = Logger::UNKNOWN

module CPEE

  module LLM

    module DataFlow

      def get_data_from_url(url,method)
        request = Typhoeus::Request.new(
          url,
          method: method,
        )
        request.run
        response = request.response
        if response.code.to_i == 200
          data = response.body
          return data
        else
          raise Exception.new "Request failed with #{response.code}!!!. \n For more details see: \n #{response.body}."
        end
      end

      def get_input(url)
        data_content = get_data_from_url("https://cpee.org/flow/resources/endpoints/#{url}/schema.rng",:get)
        doc = XML::Smart.string(data_content)
        doc.register_namespace 'd', 'http://relaxng.org/ns/structure/1.0'
        data_info = doc.find("/d:element/*").map{|e| e.dump }.join("\n")
        return data_info
      end

      def get_demo_endpoints()
        ed = get_data_from_url("https://cpee.org/flow/resources/endpoints/?description",:get)
        doc = XML::Smart.string(ed)
        resources = doc.find("//resource")
        endpoints_description = resources.map do |resource|
          [ CGI.unescape(resource.attributes['endpoint']),
            [ resource.find('string(./endpoint)'),
              resource.find('string(./functionality)'),
              get_input(resource.attributes['endpoint']),
              resource.find('string(./ouput)')
            ]
          ]
        end.to_h
        return endpoints_description
      end

      def get_idlabel_from_model(doc)
        doc.register_namespace 'd', 'http://cpee.org/ns/description/1.0'
        pairs = doc.find('//d:call').map do |c|
          [c.attributes['id'],
          c.find('string(d:parameters/d:label)')]
        end.to_h
        return pairs
      end

      EMBED_CACHE = {}

      def embed_cached(text)
        EMBED_CACHE[text] ||= begin
          emb = RagEmbeddings.embed(text, model: "mxbai-embed-large")
          RagEmbeddings::Embedding.from_array(emb)
        end
      end

      def text_similarity(string1, string2)
        obj1 = embed_cached(string1)
        obj2 = embed_cached(string2)
        return obj1.cosine_similarity(obj2)
      end

      def get_matching_endpoints(process_model,endpoints_description)
        ids = get_idlabel_from_model(process_model)
        best_match = {}
        ids.each do |i,l|
          values = endpoints_description.transform_values do |v|
            options = v[0].split(';')
            options.sum { |o| text_similarity(l, o) } / options.size.to_f
          end
          key, value = values.max_by { |_, v| v }
          ed = endpoints_description[key]
          if value > 0.70
            best_match[i] = [{"label":l, "url": key,"description": ed[0],"functionality": ed[1],"input":ed[2], "output":ed[3]}]
          end
        end
        return best_match
      end

      def integrate_dataflow(cpee_model,dataflow)
        json_e = JSON.parse(dataflow)
        endxml = XML::Smart.string('<endpoints xmlns="http://cpee.org/ns/properties/2.0"/>')

        # ========================calls=========================
        json_e['tasks'].each do |i, value|
          begin
            if value['url'] == 'script'
              cur_el = cpee_model.find("//d:call[@id='#{i}']").first
              alt = cpee_model.find('string(//d:call/@a:alt_id)')
              info = XML::Smart.string('<manipulate id="" label="" a:alt_id=""></manipulate>')
              info.root.attributes['a:alt_id'] = alt
              info.root.attributes['id'] = i
              info.root.attributes['label'] = value['label']
              info.root.add("code", value['script'])
              cpee_model.find("//d:*[@id='#{i}']").first.replace_by(info.root)
            else
              cur_task =  cpee_model.find("//d:call[@id='#{i}']").first
              label = cur_task.find('string(d:parameters/d:label)')
              #short_l = label.gsub(" ", "").downcase
              short_l = label.gsub(/[^a-zA-Z0-9]/, '').downcase
              cur_task.attributes["endpoint"] = short_l
              endxml.root.add(short_l).text = value["url"]
              # set input if exists
              if value['input'].length > 0
                args = cur_task.find('d:parameters/d:arguments').first
                value["input"].each do |i,iv|
                  if iv.is_a?(String)
                    iv = iv.start_with?("data.") ? "!#{iv}" : iv
                  end
                  args.add(i, iv)
                end
              end
            end
          rescue StandardError => e
            puts "task and script task are not consistent"
            raise e
          end

          #set output if exists
          code_fragment = XML::Smart.string(<<~XML)
            <code>
              <prepare/>
              <finalize output="result"/>
              <update output="result"/>
              <rescue output="result"/>
            </code>
          XML

          if !value['output'].nil?
            result = value['output'].map { |k, v| "#{k} = #{v}" }.join("; ")
            cur_task.add(code_fragment.root)
            finalize = cur_task.find('//d:finalize').first
            finalize.text = result
          end
        end

        pp json_e
        pp cpee_model
        # ==============================conditions (only alternative)=======================
        json_e['gateway_conditions'].each do |i, value|
          if i.end_with?("s")
            sid = i.chomp("s")
            choose = cpee_model.find("//d:choose[@eid = '#{sid}']").first
            if choose.nil?
              loop = cpee_model.find("//d:loop[@eid = '#{sid}']").first
              if loop.nil?
                #do nothing it is parralel
              else
                cur_cond = CGI.unescapeHTML(loop.attributes['condition'])
                loop.attributes['condition'] = value['branches'][cur_cond]
              end
            else
              cur_gateway =  cpee_model.find("//d:choose[@eid = '#{sid}']/d:alternative")
              cur_gateway.each do |branch|
                cur_cond = CGI.unescapeHTML(branch.attributes['condition'])
                branch.attributes['condition'] = value['branches'][cur_cond]
              end
            end
          end
        end
        return cpee_model.serialize, endxml.serialize
      end

    end

  end

end
