#!/usr/bin/env ruby

require 'nokogiri'
require 'csv'
require 'byebug'
require 'fileutils'

def query2hash(string)
    return {} if string.nil?
    string.split('&').inject({}) do |hash,keyval|
        tmp =keyval.split('=')
        hash[tmp[0]]=tmp[1]
        hash
    end
end

# ruby csv2xliff.rb translated_xliff.csv -T TargetFolder
if $stdin.tty?
  csv_filename= ARGV[0]
  unless csv_filename[-4..-1] == ".csv"
    puts "pas de fichiers csv en premier paramètre"
    exit 0
end
if ARGV[1] == '--TargetFolder' || ARGV[1] == '-T'
    folder= ARGV[2]
else
    puts "pas de dossier indiqué après --TargetFolder ou -T"
    exit 0
end
end

if folder[-1..-1]=="/"
    folder= folder[0..-2]
end

FileUtils.mkdir_p(folder)
#Read csv with header: Filename  file_params trans-unit_params   same    Source  sc  target  tc
filescollection = Hash.new(Array.new)

CSV.foreach( csv_filename ,{:headers => :string,:col_sep => ";",:encoding => "bom|utf-8"}) do |row|

    file_params=query2hash(row["File_params"])
    tu_params=query2hash(row["Trans-unit_params"])
    filescollection[row["Filename"]] += [ [file_params,tu_params,row["Source"],row["Target"]] ]
end

filescollection.each do |file,content|
    debugger if file =~ /145/
    file_params= content.first.first
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
      xml.xliff(:version => "1.2",:xmlns => "urn:oasis:names:tc:xliff:document:1.2") {
        xml.file(:original => file_params['original'],:"source-language" => file_params['source'],:"target-language" => file_params['target'],:datatype => file_params['datatype']) {
            xml.body{
            content.each do |data|
                tu= data[1]
                xml.send(:"trans-unit",:resname => tu['resname'], :restype => tu['restype'],:datatype => tu['datatype'],:id => tu['id']) {
                    xml.source{
                        xml.cdata(data[2])
                    }
                    xml.target {
                        xml.cdata(data[3])
                    }
                }
            end
          }
        }
      }
    }

    #save the file with builder.to_xml
    File.open("#{folder}/#{file}",'w+') do |f|
        f.puts builder.to_xml
    end
end
