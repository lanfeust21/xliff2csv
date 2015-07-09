#!/usr/bin/env ruby

require 'nokogiri'
require 'csv'
require 'byebug'
require 'sanitize'

# ruby xliff2csv.rb -F grundey_target
if $stdin.tty?
  if ARGV[0] == '--SourceFolder' || ARGV[0] == '-S'
    folder= ARGV[1]
  else
    puts "pas de dossier indiqué après --SourceFolder ou -S"
    exit 0
  end
end

if folder[-1..-1]=="/"
    folder= folder[0..-2]
end

files = Dir.glob(folder+'/*.xliff')
csv_filename = folder.split("/").last

class Hash
    def to_string
        size = self.size
        count= 0
        self.inject("") do |accu,(k,v)|
            count +=1
            accu  +="#{k.to_s}=#{v}"
            accu  +="&" unless count == size
            accu
        end
    end
end

CSV.open( "traductions_#{csv_filename}.csv","w+",{:col_sep => ";"}) do |csv|
    csv << ["Filename","File_params","Trans-unit_params","same","Source","sc","Target","tc"]
    files.each do |file|
        f = File.open(file)
        doc = Nokogiri::XML(f,nil,'UTF-8') do |config|
            config.options = Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET
        end

        filename     = file.split("/").last
        params        = {}
        file_params            = doc.xpath("//x:file", "x" => "urn:oasis:names:tc:xliff:document:1.2").first
        params[:original] = file_params.attr("original")
        params[:source]   = file_params.attr("source-language")
        params[:target]   = file_params.attr("target-language")
        params[:datatype] = file_params.attr("datatype")
        trans_units_params     = doc.xpath("//x:trans-unit", "x" => "urn:oasis:names:tc:xliff:document:1.2")
        sources                = doc.xpath("//x:source", "x" => "urn:oasis:names:tc:xliff:document:1.2")
        targets                = doc.xpath("//x:target", "x" => "urn:oasis:names:tc:xliff:document:1.2")
        sources.each_with_index do |source,index|
            trans_params= trans_units_params[index]
            trans_unit = {}
            trans_unit[:id]        = trans_params.attr('id')
            trans_unit[:resname]   = trans_params.attr('resname')
            trans_unit[:restype]   = trans_params.attr('restype')
            trans_unit[:datatype]  = trans_params.attr('datatype')
            source = source.text
            target = targets[index].text

            same = ((source == target) ? 1 :0)
            csv << [filename,params.to_string,trans_unit.to_string,same,source,Sanitize.clean(source).split.size,target,Sanitize.clean(target).split.size]
        end
        f.close
    end
end