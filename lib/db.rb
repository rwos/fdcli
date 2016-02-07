# database part of fdcli - Copyright 2016 by Richard Wossal <richard@r-wos.org>
# MIT licensed, see README for details
require_relative 'utils'
module DB
  include Utils

  def self.from(name, *select)
      f = File.open "#{BASEDIR}/#{name}.db", "a+"
      table = f.read().split("\n").map! do |line|
        line.split("\t").map! do |part|
          part.gsub! '\n', "\n"
          part.gsub! '\t', "\t"
          part
        end
      end
      f.close

      head = table.first
      data = table.drop 1
      return [] if head.nil? || data.nil?
      return data if select.empty?
      indices = select.map { |a| head.find_index a }
      data.map { |line| line.values_at(*indices) }
  end

  def self.json_to_db(json, *json_fields, as_string: true)
    data = json.map do |row|
      row.values_at(*json_fields).map do |datum|
        unless datum.is_a? String
          datum.to_s
        else
          datum.gsub! "\n", '\n'
          datum.gsub! "\t", '\t'
          datum = "NULL" if datum.length < 1
          datum
        end
      end
    end
    return data unless as_string
    lines = [json_fields.join("\t")]
    data.each do |row|
      lines.push row.join("\t")
    end
    lines.join("\n")
  end

  def self.into(name, json, *json_fields)
    File.write "#{BASEDIR}/#{name}.db", json_to_db(json, *json_fields)
  end

  def self.add_to_messages(name, json, *json_fields)
    old_data = from_messages name
    old_hash = {}
    old_data.each do |line|
      old_hash[line.first] = line.drop 1
    end

    new_data = json_to_db json, *json_fields, as_string: false
    new_hash = {}
    new_data.each do |line|
      new_hash[line.first] = line.drop 1
    end

    combined_hash = old_hash.merge new_hash
    combined_data = combined_hash.collect do |k, v|
      [k] + v
    end

    lines = [json_fields.join("\t")]
    combined_data.each do |row|
      lines.push row.join("\t")
    end
    lines = lines.join("\n")

    Utils.log.info "updating messages for #{name}"
    File.write "#{BASEDIR}/#{name}.messages.db", lines
  end

  def self.from_messages(name, *select)
      from "#{name}.messages", *select
  end

  def self.select(*args)
    Utils.log.info args
    -> (table) {
    }
  end

  def self.where(spec)
    -> (data) {
      data.keep_if { |line| line.first === spec }
    }
  end

  def self.fmt(spec = false, *indices)
    if spec

      spec.gsub! /\)+/, '' ### XXX TODO reset color attribs
      spec.gsub! '(selectable ', '' ### XXX TODO set color
      spec.gsub! '(selected ', '' ### XXX TODO set color

      -> (data) {
        lines = data.map do |line|
          values = line.values_at(*indices)
          begin
            spec % values
          rescue StandardError
            ''
          end
        end
        lines.join("\n")
      }
    else
      -> (data) {
        lines = data.map { |line| line.join("\t") }
        lines.join("\n")
      }
    end
  end
end
