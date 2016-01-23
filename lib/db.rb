# database part of fdcli - Copyright 2016 by Richard Wossal <richard@r-wos.org>
# MIT licensed, see README for details
require_relative 'utils'
module DB
  include Utils

  def self.from(name, *select)
      f = File.open "#{BASEDIR}/#{name}.db", File::RDONLY
      table = f.read().split("\n").map! do |line|
        line.split("\t").map! do |part|
          part.gsub! '\n', "\n"
          part.gsub! '\t', "\t"
          part
        end
      end
      f.close

      if select
        head = table.first
        data = table.drop 1
        indices = select.map { |a| head.find_index a }
        data.map { |line| line.values_at(*indices) }
      else
        table
      end
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
